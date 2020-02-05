# **Media Server SetUp on Raspberry Pi4**

[TOC]

------

## Dynamic DNS with Cloudflare

In case you do not have a rented a dedicated server or static IP, this step necessary if we want to access from any network to our server.

There are several methods such as noIP, DynDNS or others, but we will use Cloudflare and a script since it is free and we have no limitations on what we want to do.

**Steps**:

1. Buy or get a domain. There are paying domains or free domains. You can choose.
2. Register in Cloudflare.
3. Go to DNS tab and click on "+Add record" button.
4. Fill in the fields:  Type: **A**, Name: **your_domain**, IPv4 address: **0.0.0.0**, Proxy status: **DNS only**
5. Click on save.

The next thing is to download the **lwp-cloudflare-dyndns.sh** script and modify a few variables:

```bash
 	# Update these with real values
	auth_email="your_cloudflare_registration_mail"
	auth_key="your_cloudflare_api_key" 
	zone_name="your_domain"
	record_name="your_domain"
```

**Note**: The Cloudflare API key is in the **Overview button ->scroll down to API zone -> Get your API Key -> API tokens -> Global API key -> View**



The following is to save the file in a folder, for example in /home/pi/cloudflare-script. 

```bash
	mkdir /home/pi/cloudflare-script
```



Next, we must make it run every X time, for that we will use **crontab**. For that we write in a terminal:

```bash
	crontab -e
```

And paste the following:

```
	*/40 * * * * /bin/bash /home/pi/cloudflare-script/lwp-cloudflare-dyndns.sh
```

This order will make the script run every 40 minutes and update our public IP to Cloudflare.

**Note**: If we have problems with the permissions when executing this script we will only have to give it permissions with **chmod**.

If we return to the Cloudflare page -> DNS button, we can see that the IP for which we have now has been updated!

****

## Mount GDrive Units

First we will have to have **rclone** installed and **at least one unit** added to rclone. I will not expand on this since there are many articles on the net about this.

Next, we have to create a local folder in which we want to mount our GDrive drive:

```bash
	mkdir /mnt/cloudrive
```

Next, we create a script to mount the unit every time our raspberry pi turns on:

```
	nano /etc/systemd/system/rclone.service
```

Paste this:

```bash
[Unit]
Description=rclone Google Drive FUSE mount
Documentation=http://rclone.org/docs/
After=network-online.target

[Service]
Type=simple
User=pi
Group=pi
ExecStart=/usr/bin/rclone mount \
        --allow-non-empty \
        --allow-other \
        --buffer-size 256M \
        --dir-cache-time 72h \
        --drive-chunk-size 64M \
        --vfs-read-chunk-size 128M \
        --vfs-read-chunk-size-limit off \
        --vfs-cache-mode=writes \
        --max-transfer 750G \
        --config /home/pi/.config/rclone/rclone.conf usal:/ /mnt/cloudrive

ExecStop=/bin/fusermount -u /mnt/cloudrive
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
```

**Note**: Pay attention to the name **cloudrive**, since this if you have created the folder with another name, the name of the folder has to go here where you put cloudrive.

**Note 2**: --max-transfer 750G is to prevent GDrive banning if you go over this traffic.

**Note 3**: This argument: 

```bash
--config /home/pi/.config/rclone/rclone.conf
```

is to pass the path of the *rclone* configuration file.

**Note 4**: If there is a problem with **--allow-other** you have to do this:

```bash
	nano /etc/fuse.conf
```

Uncomment this line in the file:

```bash
	#user_allow_other
```

to:

```bash
	user_allow_other
```

Restart the raspberry and you will have the Gdrive unit mounted!



### Optional:

If you want to make a backup on another gdrive unit of the first unit, **you just have to add the second drive to rclone** and then:

1. Open crontab on a Terminal:

   ```bash
   	crontab -e
   ```

2. Add this line to crontab:

   ```bash
       0 1 * * * rclone sync source_unit:source_unit_folder dest_unit:dest_folder --max-transfer 750G
   ```
   Explanation:
   
   **source_unit**: Name of the source unit we have added to rclone.
   
   **source_unit_folder**: Name of the folder inside the Gdrive drive that we want to backup.
   
   **dest_unit**: Name of the destination unit we have added to rclone.
   
   **dest_folder**: Name of the folder inside dest_unit where we want the backup to be saved.
   
   

------

## Mount USB HDD

To mount a USB-connected HDD in the location that we want you will have to do:

1. Create a folder to mount.
	```bash
   	sudo mkdir /mnt/hdd
   ```
   
2. Edit fstab file:
	```bash
   	sudo nano /etc/fstab
   ```
   
3. Paste this line:

   ```bash
   UID=your_hdd_uuid /mnt/hdd TYPE defaults,auto,users,rw,nofail 0 0
   ```
   
   **Note**: replace **your_hdd_uuid** with the HDD UUID and the TYPE variable with the type of filesystem of your HDD and if it is **ntfs** add it right after nofail this: "**, umask = 000**".
   
   
   

------

## NGINX Reverse Proxy

This configuration varies depending on what you want. In my case I want to do reverse proxy for **transmission**, **radar** and **pymedusa**.

For this, install **NGINX**  & Certbot with:

```bash
sudo apt-get install nginx
sudo apt-get install certbot python-certbot-nginx
```

Then create a file in named **[domain_name].conf** with:

```bash
sudo nano /etc/nginx/sites-enabled/[domain_name].conf
```

Now we are going to create the certificates with **Cerbot**:

```bash
sudo certbot --nginx
```

A wizard will open to configure it. We follow the steps and it is important to select the domain you want to configure when it appears.

**Note**: This file ***nginx_services.conf*** shows how our NGINX configuration file should be. The file is in the repository.

**Note 2**: The services need some configuration (the files are in the repository). Then I leave the important lines for the configuration of NGINX:

- **Radarr** *[radarr]config.xml*

  ```xml
  <Port>7878</Port>
  <BindAddress>*</BindAddress>
  <SslPort>7878</SslPort>
  <UrlBase>/radarr/</UrlBase>
  <EnableSsl>False</EnableSsl>
  ```

- **Medusa** *[medusa]config.ini*

  ```ini
  web_root = /medusa
  enable_https = 0
  handle_reverse_proxy = 0
  ```

- **Transmission** *[transmission]settings.json*

  ```json
  "port-forwarding-enabled": true,
  "rpc-bind-address": "127.0.0.1",
  "rpc-enabled": true,
  "rpc-url": "/transmission/",
  "rpc-whitelist": "127.0.0.1",
  "rpc-whitelist-enabled": false,
  ```

------

## Optional Files

*lwp-cloudflare-dyndns.sh* : Script to update the public IP to your Cloudflare's account.

*unrar-torrents-script.sh* : Script to decompress files when transmission downloads finish.

*[radarr]config.xml* : Radarr configuration file.

*[medusa]config.ini* : Medusa configuration file.

*[transmission]settings.json* : Transmission configuration file.