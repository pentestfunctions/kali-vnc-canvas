# 🔐 Kali-VNC-Canvas

> Control your Kali Linux VMs through Obsidian Canvas with this seamless VNC integration

![GitHub stars](https://img.shields.io/github/stars/pentestfunctions/kali-vnc-canvas?style=social)
![License](https://img.shields.io/github/license/pentestfunctions/kali-vnc-canvas)

## 📑 Overview

This project provides a streamlined way to access and control your Kali Linux VMs directly from Obsidian using the Canvas plugin. By embedding VNC connections as interactive web frames within your Canvas boards, you can:

- 🧩 Integrate VM control directly into your pentest documentation
- 🖥️ Manage multiple VMs from a single interface
- 📝 Take notes alongside your active VM sessions
- 🔄 Create workflows that combine documentation, commands, and VM control

Perfect for security researchers, ethical hackers, and cybersecurity educators who use Obsidian for note-taking and want to enhance their workflow.

![Demo Gif](https://github.com/pentestfunctions/kali-vnc-canvas/blob/main/assets/Canva_Setup.gif)

## 🚀 Quick Start

### Prerequisites

- A running Kali Linux VM (tested with the official Kali Linux Hyper-V image)
- [Obsidian](https://obsidian.md/) with the [Canvas plugin](https://obsidian.md/canvas) installed

### Installation

#### On Your Kali Linux VM:

1. Clone this repository directly on your Kali Linux VM:
   ```bash
   git clone https://github.com/pentestfunctions/kali-vnc-canvas.git
   cd kali-vnc-canvas
   ```

2. Run the installer script:
   ```bash
   chmod +x installer-vnc.sh
   ./installer-vnc.sh
   ```

3. Follow the prompts to set your VNC password.

4. Note the VNC and NoVNC web access URLs displayed at the end of the installation.

![Installation Process](https://raw.githubusercontent.com/pentestfunctions/kali-vnc-canvas/main/assets/installation-demo.gif)

## 🔧 Usage

### Setting Up in Obsidian Canvas

1. Open Obsidian and make sure the Canvas plugin is enabled:
   - Go to Settings → Community plugins → Browse
   - Search for "Canvas" and install it
   - Enable the plugin

   ![Enable Canvas Plugin](https://raw.githubusercontent.com/pentestfunctions/kali-vnc-canvas/main/assets/enable-canvas.gif)

2. Create a new Canvas by clicking on the Canvas icon in the left sidebar or using the command palette.

   ![Create New Canvas](https://raw.githubusercontent.com/pentestfunctions/kali-vnc-canvas/main/assets/create-canvas.gif)

3. Right-click on the canvas and select "Add iframe."

4. Enter the NoVNC URL provided by the installer script:
   ```
   http://your-vm-ip:8080/vnc.html
   ```

5. Adjust the frame size as needed (recommended: at least 800×600).

6. Connect to your VM by clicking in the frame and entering your VNC password.

   ![Add VNC to Canvas](https://raw.githubusercontent.com/pentestfunctions/kali-vnc-canvas/main/assets/add-vnc-to-canvas.gif)

7. You can now interact with your Kali Linux VM directly within Obsidian!

   ![Using VNC in Canvas](https://raw.githubusercontent.com/pentestfunctions/kali-vnc-canvas/main/assets/using-vnc.gif)

### Managing Your VNC Server

- **Start VNC server:** Run `~/start-vnc.sh` on your Kali VM
- **Stop VNC server:** Run `pkill -f x11vnc` on your Kali VM
- **Change VNC password:** Run `x11vnc -storepasswd ~/.vnc/passwd`

## 💡 Tips for Effective Use

- Create dedicated Canvas boards for different penetration testing projects
- Organize your commands, notes, and VM access in logical clusters
- Use canvas connection lines to map attack paths and workflows
- Add text notes with common commands next to your VM for quick reference
- Create multiple iframes to control several VMs at once
- Take screenshots directly from VNC and paste them into your Canvas
- Use different colored backgrounds or notes to categorize different types of activities
- Create templates with common tools and commands around your VM frame

![Canvas Workflow Example](https://raw.githubusercontent.com/pentestfunctions/kali-vnc-canvas/main/assets/canvas-workflow.gif)

## 🔒 Security Considerations

- The VNC connection is unencrypted by default. For production or internet-facing setups, consider using SSH tunneling
- Always use strong VNC passwords
- Restrict access to your VNC port with a firewall
- Consider implementing IP-based access restrictions

## 🔍 Troubleshooting

### Common Issues

#### VNC Connection Fails
- Ensure x11vnc is running (`ps aux | grep x11vnc`)
- Check if port 5900 is open (`netstat -tuln | grep 5900`)
- Verify your firewall settings (`sudo ufw status`)

#### Black Screen in VNC
- Make sure a desktop session is active on the VM
- Try restarting the X session
- Check x11vnc logs (`cat /tmp/x11vnc.log`)

#### NoVNC Web Interface Not Working
- Verify websockify is running (`ps aux | grep websockify`)
- Ensure port 8080 is open
- Check the novnc installation directory

## 📋 Advanced Configuration

### Customizing VNC Settings

The installer script creates a `start-vnc.sh` file in your home directory. You can edit this file to:

- Change the VNC or NoVNC ports
- Add additional security options
- Configure startup parameters
- Add custom logging

Example of adding encryption to your connection:
```bash
# Add this to your start-vnc.sh
x11vnc -display $DISPLAY -forever -shared -rfbauth ~/.vnc/passwd -ssl SAVE -sslonly -rfbport 5900 -bg
```

### Canvas Organization Tips

For the best experience organizing your pentesting workflow:

1. **Create a structured Canvas layout:**
   - VM controls in the center
   - Command references on the left
   - Note-taking area on the right
   - Results/evidence collection at the bottom

2. **Use color coding:**
   - Red for critical findings
   - Yellow for potential vulnerabilities
   - Green for completed tests
   - Blue for references and resources

   ![Canvas Organization](https://raw.githubusercontent.com/pentestfunctions/kali-vnc-canvas/main/assets/canvas-organization.gif)

3. **Link multiple canvases:**
   - Main overview canvas
   - Detailed canvas for each target
   - Methodology reference canvas
   - Tool-specific canvas views
