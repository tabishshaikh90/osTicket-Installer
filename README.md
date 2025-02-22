# 🚀 osTicket Auto-Installer Script for Ubuntu

This script **automates the installation of osTicket** on an Ubuntu server. It dynamically fetches the latest version, installs all required dependencies (including **APCu for better performance**), sets up the database, and properly configures Apache.

## 📌 Features:
✅ **One Command Installation** - Just run one command, and osTicket is installed!  
✅ **Fetches the Latest osTicket Version** - Always installs the latest stable release.  
✅ **Handles Database Setup** - Allows you to use, delete, or reset an existing database.  
✅ **Includes APCu Extension** - Improves osTicket performance.  
✅ **Renames Config File** - Automatically renames `ost-sampleconfig.php` to `ost-config.php`.  
✅ **Clean Output & Error Handling** - Detects issues and provides solutions.  

---

## **💻 Installation (One Command)**
Run the following command in your terminal:
```bash
bash <(curl -s https://raw.githubusercontent.com/tabishshaikh90/osTicket-Installer/main/install.sh)
OR

bash
Copy
Edit
wget -qO- https://raw.githubusercontent.com/tabishshaikh90/osTicket-Installer/main/install.sh | bash

📜 What This Script Does
1️⃣ Installs all necessary packages (Apache, PHP, MariaDB, etc.).
2️⃣ Fetches the latest stable osTicket release from GitHub.
3️⃣ Starts and enables Apache & MariaDB services.
4️⃣ Prompts user for database setup:

Use an existing database
Delete and recreate
Clear all data
5️⃣ Creates the osticket database user and assigns privileges.
6️⃣ Downloads & extracts osTicket into /var/www/html/osticket.
7️⃣ Renames ost-sampleconfig.php to ost-config.php for easier installation.
8️⃣ Sets file permissions and enables Apache rewrite module.
9️⃣ Provides the URL and database credentials for final setup.
🛠 Requirements
Ubuntu 20.04 / 22.04 (Tested)
Root or sudo access
Internet connection
📌 After Installation
Open your browser and go to:
bash
Copy
Edit
http://your-server-ip/osticket
Follow the on-screen setup instructions.
Enter the database details shown at the end of the installation.
Complete the installation and remove the setup/ folder for security.
🆘 Troubleshooting
❌ osTicket ZIP File Not Found
✔ Run: rm -f /var/www/html/osticket.zip and try again.

❌ Apache Not Starting?
✔ Check the status: sudo systemctl status apache2

❌ MariaDB Not Running?
✔ Restart it: sudo systemctl restart mariadb

📜 License
This script is open-source under the MIT License.
Feel free to contribute and improve it!

💙 Like This Project?
⭐ Star this repository on GitHub
🔄 Fork and contribute
🐛 Report issues

Enjoy your fully automated osTicket setup! 🚀🔥
