# ECSU - EBS Component Search Utility
Artifact Download Utility for Oracle EBS Application.

This Application will enable the to search for custom Oracle EBS components efficiently via a user-friendly interface. 
Component types include concurrent programs, custom packages, tables, views, workflows, and more.

## ECSU ORACLE - Components
This repository contains the Oracle Components Required for the ECSU tool and the required ZIPs with JAR files and docker compose 
for the container side of ECSU.

**Search Dash :**

<img width="1233" height="353" alt="image" src="https://github.com/user-attachments/assets/e3cf021d-9e13-452d-9f08-45e3e6959bb8" />

<img width="1172" height="924" alt="image" src="https://github.com/user-attachments/assets/cad25a6e-2274-4f62-905c-4f74c930df6d" />


**User and Instance Managment :**


<img width="1281" height="550" alt="image" src="https://github.com/user-attachments/assets/524ae928-3c10-4323-ae7b-04ce13e99c2c" />

<img width="1200" height="375" alt="image" src="https://github.com/user-attachments/assets/11ce2c22-3327-4cb8-af9f-16ffaef7aa20" />



## ECSU Non Oracle Setup -- Installtion Instructions

This guide provides step-by-step instructions for installing and running the ECSU application using Docker. 
The setup uses a docker-compose.yml file to manage all the necessary services.

## Prerequisites
Before you begin, please ensure you have the following installed and configured on your system:

Docker & Docker Compose: You need a recent version of Docker Engine and Docker Compose. 
The recommended way to get this is by installing Docker Desktop (for Mac/Windows) or Docker Engine (for Linux).

Installation Package: Download the latest installation package from the official release section (ECSU_INSTALLATION.zip).

Extraction: Extract the contents of the downloaded package into your desired installation directory.

Terminal/Command Line: All commands should be executed from within the root of the extracted installation directory 
(i.e., the same directory where the docker-compose.yml file is located).

## Installation & Setup (Non Oracle Setup)
The installation process is broken down into the below steps:

1) Fetches/Creates docker HasiCorp-vault & postgres images and setups the required KV secrets & Schemas respectively

       docker compose up -d --build vault pg vault-setup vault-proxy-backend vault-agent-kc db-init
   
2) Fetches/Creates docker image for keycloak (IDM provider , Admin login is created with user/password : admin/admin)
   
        docker compose up -d --build keycloak

3) Setting up the keycloak with required relams, role (for RBAC access) and initial seeded app user 
   
        docker compose up --abort-on-container-exit --build keycloak-setup

4) Creates the Java Sprinboot backend image and container
   
        docker compose up -d --build backend

5) Creates the React frontend image and container
   
        docker compose up -d --build frontend

## ❗ Important: Post-Installation Security Steps (Non Oracle Setup)
For security reasons, the initial setup creates temporary administrative and user accounts. Please follow these steps immediately after your first login to secure your installation.

1. Secure the Keycloak Admin Account
   
   The seeded admin user for the Keycloak console is temporary and should be replaced.
   
   i)  Login to keycloak dashboard with the initial user/password : admin/admin
   
   ii) Either create a new admin account or reset the admin password for current admin account
       Navigation for reset -- >
   
       a)  Users (master Realmn) ---> Click on ADMIN user --> credentials --> Click on Reset password (make sure temporary is off)  

3. The Temporary Application User (ECSU_USER)

   The seeded app admin user for the App could be deleted or password can be reset.
   
   i)  Login to the app via frontend with seeded user - password (ECSU_USER - 123), keycloak will ask you to reset password on first login

      OR

      Login to Keycloak as Admin, Navigate (Relam - ECSU) to Users section and reset the password for ECSU_USER
      or create a new user and delete the seeded one.
   
   ii) In keycloak console setup your proper password requirements

**Note:** New users are approved via App's User Management have default password - ChangeIt123, and will be prompted to updated on thier first login (this will chnage in future releases)

## 🔧 Mandatory: Configure SMTP for Email Functionality

For the ECSU application to be fully functional, the deploying administrator **must** configure Keycloak to connect to an SMTP mail server. This is essential for critical features like user email verification and password resets.

As this application is intended for enterprise use, you will need to use your organization's internal SMTP server details.

**Action Required:**
1.  Navigate to the Keycloak Admin Console
2.  Go to **Realm Settings** > **Email** tab.
3.  Fill in the connection details for your organization's SMTP server.
4.  Update Email requirements setting and turn on email verification.
5.  Use the **Test connection** button to ensure the configuration is correct.

**Note:** Without completing this step, users will not be able to reset their passwords or verify their accounts.
    
   
