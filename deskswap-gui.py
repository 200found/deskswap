#!/usr/bin/env python3

import os
import sys

from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import (
    QApplication,
    QWidget,
    QLabel,
    QListWidget,
    QListWidgetItem,
    QLineEdit,
    QPushButton,
    QFileDialog,
    QMessageBox,
    QVBoxLayout,
    QHBoxLayout,
)

SCRIPT_DIR = os.path.dirname(
    os.path.abspath(__file__)
)

HISTORY_FILE = os.path.join(
    SCRIPT_DIR,
    "deskswap.history"
)


def normalize_path(path):
    return os.path.realpath(
        os.path.abspath(
            os.path.expanduser(path)
        )
    )


class HistoryEditor(QWidget):

    def __init__(self):
        super().__init__()

        self.default_path = None
        self.paths = []

        self.setWindowTitle(
            "Deskswap History Editor"
        )

        self.resize(800, 500)

        self.build_ui()
        self.load_history()


    def build_ui(self):

        layout = QVBoxLayout(self)

        #
        # Header
        #
        layout.addWidget(
            QLabel(
                "Enable or disable desktop directories:"
            )
        )

        #
        # History list
        #
        self.list_widget = QListWidget()

        self.list_widget.setSelectionMode(
            QListWidget.SelectionMode.NoSelection
        )

        self.list_widget.itemDoubleClicked.connect(
            self.toggle_item
        )

        layout.addWidget(
            self.list_widget
        )

        #
        # Add section
        #
        layout.addWidget(
            QLabel(
                "Add a new desktop directory:"
            )
        )

        add_layout = QHBoxLayout()

        self.path_edit = QLineEdit()

        self.path_edit.returnPressed.connect(
            self.add_directory
        )

        add_button = QPushButton(
            "Add"
        )

        add_button.clicked.connect(
            self.add_directory
        )

        choose_button = QPushButton(
            "Choose..."
        )

        choose_button.clicked.connect(
            self.choose_directory
        )

        add_layout.addWidget(
            self.path_edit
        )

        add_layout.addWidget(
            add_button
        )

        add_layout.addWidget(
            choose_button
        )

        layout.addLayout(
            add_layout
        )

        #
        # Bottom buttons
        #
        button_layout = QHBoxLayout()

        update_button = QPushButton(
            "Update and Exit"
        )

        update_button.clicked.connect(
            self.update_and_exit
        )

        cancel_button = QPushButton(
            "Cancel"
        )

        cancel_button.clicked.connect(
            self.close
        )

        button_layout.addWidget(
            update_button
        )

        button_layout.addWidget(
            cancel_button
        )

        layout.addLayout(
            button_layout
        )

    def load_history(self):

        if not os.path.exists(
            HISTORY_FILE
        ):
            return

        with open(
            HISTORY_FILE,
            "r",
            encoding="utf-8"
        ) as f:

            lines = [
                normalize_path(line.strip())
                for line in f
                if line.strip()
            ]

        if not lines:
            return

        #
        # Save permanent desktop path.
        #
        self.default_path = lines[0]

        seen = set()

        for path in lines[1:]:

            if path in seen:
                continue

            seen.add(path)

            self.add_history_item(
                path
            )

    def add_history_item(
        self,
        path
    ):

        if (
            path == self.default_path
            or path in self.paths
        ):
            return

        item = QListWidgetItem(
            path
        )

        item.setFlags(
            item.flags()
            | Qt.ItemFlag.ItemIsUserCheckable
        )

        item.setCheckState(
            Qt.CheckState.Checked
        )

        self.list_widget.addItem(
            item
        )

        self.paths.append(
            path
        )

    def toggle_item(
        self,
        item
    ):

        if (
            item.checkState()
            == Qt.CheckState.Checked
        ):
            item.setCheckState(
                Qt.CheckState.Unchecked
            )
        else:
            item.setCheckState(
                Qt.CheckState.Checked
            )

    def choose_directory(self):

        directory = QFileDialog.getExistingDirectory(
            self,
            "Choose Directory"
        )

        if directory:
            self.path_edit.setText(
                directory
            )

    def add_directory(self):

        path = self.path_edit.text().strip()

        if not path:
            return

        path = normalize_path(
            path
        )

        if not os.path.isdir(path):

            QMessageBox.warning(
                self,
                "Invalid Directory",
                f"Directory does not exist:\n\n{path}"
            )

            return

        if (
            path == self.default_path
            or path in self.paths
        ):

            QMessageBox.information(
                self,
                "Already Present",
                "Directory already exists in history."
            )

            self.path_edit.clear()

            return

        self.add_history_item(
            path
        )

        self.path_edit.clear()

        self.list_widget.scrollToBottom()

    def update_and_exit(self):

        selected = []

        for index in range(
            self.list_widget.count()
        ):

            item = self.list_widget.item(
                index
            )

            if (
                item.checkState()
                == Qt.CheckState.Checked
            ):
                selected.append(
                    item.text()
                )

        try:

            with open(
                HISTORY_FILE,
                "w",
                encoding="utf-8"
            ) as f:

                #
                # Always preserve
                # permanent desktop path.
                #
                if self.default_path:
                    f.write(
                        self.default_path
                        + "\n"
                    )

                for path in selected:
                    f.write(
                        path
                        + "\n"
                    )

        except Exception as exc:

            QMessageBox.critical(
                self,
                "Write Error",
                str(exc)
            )

            return

        self.close()

    def keyPressEvent(
        self,
        event
    ):

        if (
            event.key()
            == Qt.Key.Key_Escape
        ):
            self.close()
            return

        super().keyPressEvent(
            event
        )


def main():

    app = QApplication(
        sys.argv
    )

    window = HistoryEditor()

    window.show()

    sys.exit(
        app.exec()
    )


if __name__ == "__main__":
    main()
