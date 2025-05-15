import os
import shutil
import sys
import datetime
from PyQt5.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QPushButton, QFileDialog,
    QLabel, QMessageBox, QCheckBox, QComboBox
)

class FileOrganizer(QWidget):
    def _init_(self):
        super()._init_()
        self.setWindowTitle("Advanced File Organizer")
        self.setGeometry(100, 100, 500, 300)

        self.layout = QVBoxLayout()

        # Folder selection label
        self.folder_label = QLabel("No folder selected.")
        self.layout.addWidget(self.folder_label)

        # Date organizing checkbox
        self.date_checkbox = QCheckBox("Organize by Date Created (Year/Month)")
        self.layout.addWidget(self.date_checkbox)

        # Extension organizing checkbox
        self.extension_checkbox = QCheckBox("Organize by File Type")
        self.extension_checkbox.setChecked(True)
        self.layout.addWidget(self.extension_checkbox)

        # Sort method dropdown (future use)
        self.sort_combo = QComboBox()
        self.sort_combo.addItems(["By Extension", "By Date", "By Size"])
        self.layout.addWidget(QLabel("Sort Method:"))
        self.layout.addWidget(self.sort_combo)

        # Folder selection button
        self.folder_button = QPushButton("Choose Folder")
        self.folder_button.clicked.connect(self.choose_folder)
        self.layout.addWidget(self.folder_button)

        # Start organizing
        self.start_button = QPushButton("Start Organizing")
        self.start_button.clicked.connect(self.start_organizing)
        self.layout.addWidget(self.start_button)

        # Status label
        self.status_label = QLabel("")
        self.layout.addWidget(self.status_label)

        self.setLayout(self.layout)

    def choose_folder(self):
        folder = QFileDialog.getExistingDirectory(self, "Select Folder")
        if folder:
            self.selected_folder = folder
            self.folder_label.setText(f"Selected: {folder}")

    def start_organizing(self):
        if not hasattr(self, 'selected_folder') or not self.selected_folder:
            QMessageBox.warning(self, "No Folder", "Please select a folder first.")
            return
        self.organize_files(self.selected_folder)

    def get_unique_path(self, target_folder, filename):
        base, ext = os.path.splitext(filename)
        counter = 1
        new_filename = filename
        while os.path.exists(os.path.join(target_folder, new_filename)):
            new_filename = f"{base}_{counter}{ext}"
            counter += 1
        return os.path.join(target_folder, new_filename)

    def organize_files(self, folder):
        for filename in os.listdir(folder):
            file_path = os.path.join(folder, filename)

            if not os.path.isfile(file_path):
                continue

            ext = filename.split('.')[-1].lower() if '.' in filename else ''
            category_folder = 'Others'

            match ext:
                case 'jpg' | 'png' | 'jpeg' | 'gif' | 'bmp':
                    category_folder = 'Images'
                case 'mp4' | 'mkv' | 'avi' | 'mov':
                    category_folder = 'Videos'
                case 'mp3' | 'wav' | 'aac' | 'flac':
                    category_folder = 'Music'
                case 'pdf' | 'docx' | 'doc' | 'txt' | 'xlsx' | 'pptx':
                    category_folder = 'Documents'
                case 'zip' | 'rar' | '7z':
                    category_folder = 'Archives'
                case 'exe' | 'msi':
                    category_folder = 'Installers'
                case _:
                    category_folder = 'Others'

            if self.extension_checkbox.isChecked():
                target_folder = os.path.join(folder, category_folder)
            else:
                target_folder = os.path.join(folder, "Unsorted")

            # Add date subfolder if option is checked
            if self.date_checkbox.isChecked():
                created_time = os.path.getctime(file_path)
                date = datetime.datetime.fromtimestamp(created_time)
                year_folder = str(date.year)
                month_folder = date.strftime("%B")
                target_folder = os.path.join(target_folder, year_folder, month_folder)

            os.makedirs(target_folder, exist_ok=True)

            if os.path.dirname(file_path) == target_folder:
                continue  # Skip if already in correct folder

            dest_path = self.get_unique_path(target_folder, filename)

            try:
                shutil.move(file_path, dest_path)
                self.status_label.setText(f"Moved: {filename}")
                QApplication.processEvents()
            except Exception as e:
                QMessageBox.warning(self, "Error", f"Could not move {filename}:\n{str(e)}")

        QMessageBox.information(self, "Done", "Files have been organized.")
        self.status_label.setText("Organizing complete.")

if _name_ == "_main_":
    app = QApplication(sys.argv)
    window = FileOrganizer()
    window.show()
    sys.exit(app.exec_())
