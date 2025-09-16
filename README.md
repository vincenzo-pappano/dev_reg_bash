<h1>A bash utility to support the device registry API</h1>


<h2>Manual Interaction with the Device Registry</h2>

Once a certificate has been attached to a device, the device can be registered with the Device Registry (**"Import from FMS"**) and then sent to the backend (**"Send to IoT.ON"**)


<h2>Certificate background</h2>
The certificates are acquired through a Jenkins job. A single certificate is attached to the charger's mainboard. The certificate is then imported into the Device Registry and sent to IoT.ON

<details>
  <summary><h4>Additional Details</h4></summary>

  -----
  
  <img  style="border:3px solid black;" width="600" src="images/Create AWS Certificate.png">
  
  -----
  
  Running the AWS certificate creation Jenkins jobs (for an environment ID/customer ID pair) will produce the following (for a single certificate):
   - devprefix
   - uri
   - serial
   - ca.crt
   - client.key
   - client.crt
   - DevReg-datetime.json
   - FMS-datetime.json

For instance, for multi-us/multi-test

    devprefix: multi-test-

    uri:       ssl://a2dywi8p63m7bi-ats.iot.us-east-1.amazonaws.com:8883

    serial:    66a32c7e4cb64a29f5c44d9941c62e0ba649bb07b7b9a39876e6be8815d7febd

    ca.crt:
               -----BEGIN CERTIFICATE-----
               MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF ... rqXRfboQnoZsG4q5WTP468SQvvG5
               -----END CERTIFICATE-----

    client.key:
               -----BEGIN RSA PRIVATE KEY-----
               MIIEowIBAAKCAQEA1cnzBLJl8h1dXvIFtLbYSEGNc3JCEB+T4azHl+G0rS5OU7RV ... /CJ5b9kIjaslJKpVs98G9u37F1jy
               -----END RSA PRIVATE KEY-----

    client.crt:
               -----BEGIN CERTIFICATE-----
               MIIDWTCCAkGgAwIBAgIUVZ4xOO+Ubn+B/CG7silhvzEcfeAwDQYJKoZIhvcNAQEL ... HO0KdIgUKza+IhOeU2Ysk0SWjlVH
               -----END CERTIFICATE-----


The files **ca.crt**, **client.key**, and **client.crt** are then base64 encoded. The new files are embedded into **FMS-datetime.json**

    [
       {
          "serial_number": 0,
          "root_cert":       "LS0tLS1CRUdJTiBDRVJUSUZJQ0 ... vUW5vWnNHNHE1V1RQNDY4U1F2dkc1Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K",
          "client_cert":     "LS0tLS1CRUdJTiBDRVJUSUZJQ0 ... VS3phK0loT2VVMllzazBTV2psVkgKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
          "client_priv_key": "LS0tLS1CRUdJTiBSU0EgUFJJVk ... KS3BWczk4Rzl1MzdGMWp5Ci0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==",
          "uri": "a2dywi8p63m7bi-ats.iot.us-east-1.amazonaws.com"
       },
    ]

and **DevReg-datetime.json**

    [
      {
        "serial_number": 0,
        "firmware_version": "",
        "created_date": "1756937206798",
        "uuid": "",
        "customer_id": "multi-test",
        "client_id": "multi-test-",
        "provisioning_certificate": {
          "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0 ... VS3phK0loT2VVMllzazBTV2psVkgKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
        }
    }
  ]

**DevReg-datetime.json** is a blank certificate and needs to be associated with a device (the charger's mainboard). For instance, if the mainboard ID is: **IOTPAPPVIDEO0000005**, the new file contents are (the file has been renamed for convenience):

**DevReg-datetime-IOTPAPPVIDEO0000005.json**

    [
      {
        "serial_number": 0,
        "firmware_version": "",
        "created_date": "1756937206798",
        "uuid": "IOTPAPPVIDEO0000005",
        "customer_id": "multi-test",
        "client_id": "multi-test-IOTPAPPVIDEO0000005",
        "provisioning_certificate": {
          "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0 ... VS3phK0loT2VVMllzazBTV2psVkgKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
        }
    }
  ]
</details>



<h2>Bash Scripts</h2>

Assumptions: username and passwords are environment variables, the JSON file with a single certificate has already been attached to a mainboard

Script (1) **. ./dev_reg_auth.sh MFA**

<details>
<summary><h4>Details</h4></summary>
    pi@raspberrypi5:~/ioton $ . ./dev_reg_auth.sh 150282
    
    HTTP_STATUS=200
    
    === HEADERS ===
    HTTP/1.1 200 OK
    Date: Mon, 15 Sep 2025 00:12:44 GMT
    Content-Type: application/json
    Content-Length: 455
    Connection: keep-alive
    apigw-requestid: Q6r_gjmKoAMEJdQ=
    
    
    access_key            : ASIAUNUA4FKZTGYZL6KQ
    secret_access_key     : 4yHNDzmQTiP43dXSTRz7P7SilnH5GglezdFrlvtK
    session_token         : FwoGZXIvYXdzEAIaDFMNr6xUXPO9XjQG5SKpAfPsQSqk7B3JacMF3CTcupBZdPXyHWvTG4dvl9JfCwG3mH3SVSbSV8kgHFaNEQDzu/kzPqxIC2s7mJBMUITsJl4IaEH9iahptjxdf5Jd3/MPdVhyV1VTEqK0T2R62DMDRL8AyCfLTTcJQ1EE96sUhZXhKOGYpLuH3vpeZJcqinjX7PE0JoINxHvZiMY4lSEvLwxKaI70wLyKlS4nldTQElsj8ks1nuaYciUo/LOdxgYyLbBw9Ojn2vdcKh/mA2Ja+VK+9Ya2bDB2i1YixzmrT9JNwiPFyt3bYiIPKSAhsQ==
    AWS_ACCESS_KEY_ID     : ASIAUNUA4FKZTGYZL6KQ
    AWS_SECRET_ACCESS_KEY : 4yHN…lvtK
    AWS_SESSION_TOKEN     : FwoG…sQ==
    
    Auth OK. access_key / secret_access_key / session_token exported.
</details>


Script (2) **. ./dev_reg_register.sh DevReg-0009.json**

<details>
<summary><h4>Details</h4></summary>
    pi@raspberrypi5:~/ioton $ . ./dev_reg_register.sh DevReg-0009.json 
    
    === PAYLOAD ===
    {
      "created_date": "1756937207185",
      "uuid": "IOTPAPPVIDEO0000009",
      "customer_id": "multi-test",
      "client_id": "multi-test-IOTPAPPVIDEO0000009",
      "provisioning_certificate": {
        "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURXVENDQWtHZ0F3SUJBZ0lVZk02N0g0dlByb1pidTFGNHhCeGJlTjRMakVZd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1RURkxNRWtHQTFVRUN3eENRVzFoZW05dUlGZGxZaUJUWlhKMmFXTmxjeUJQUFVGdFlYcHZiaTVqYjIwZwpTVzVqTGlCTVBWTmxZWFIwYkdVZ1UxUTlWMkZ6YUdsdVozUnZiaUJEUFZWVE1CNFhEVEkxTURrd016SXlNRFEwCk4xb1hEVFE1TVRJek1USXpOVGsxT1Zvd0hqRWNNQm9HQTFVRUF3d1RRVmRUSUVsdlZDQkRaWEowYVdacFkyRjAKWlRDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBS0JkdFg4Z1YxR25PbGY3dGRZZwo0VEhaUlh2U3c0TEQya0xOSDdEMFVxSnZxUjZyekJDcEx4YXVzWTZodFdmdHVJdjlSQmNvcGU2bDNSNE83L0drCnRNNXdjS1BwbytKRGcyMTB2L003c0h5aXRRZWlJZ0FVenFGZTk0RXJHQ0VVTWRmVTRWTE5kclBBT1gyNEZuQ3UKUTZHNjJpM0t3RmNHN1l4cnZaOU95N2p4VytWNVVJN1FQbWlGeG04c1UrcTFYbkRUUWpTRWY4dVNLMjR5UzB4QQpYcnpTTTUyQ3loSkwrQXNrL1J6b2VzVEhkSGFqeEVYY09OZEI4SEt5Qm1IRnUrdXJTUXU5cjRvWDM1VGRBaGl2ClhWTlJMc2FlWGxGbVgzRlNwMXRjb3dEZmhEREZmYStlVmNMblc3RDNVNVNDbysrOHhtU3V6MEIzdy9ZWDAvZ0UKZmprQ0F3RUFBYU5nTUY0d0h3WURWUjBqQkJnd0ZvQVV0cGkrS25vV25IcWhvVExQdlZoNlJvdFI1dGN3SFFZRApWUjBPQkJZRUZKd0JUYXcvLzM3eGsxS3JtWm5XQ2x2Nk54b0FNQXdHQTFVZEV3RUIvd1FDTUFBd0RnWURWUjBQCkFRSC9CQVFEQWdlQU1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQTJqdzZvR1JsRGdmSmY1VWx3M1kzZXhGQU0KQnNRWWt4S1B3SjBKTTZiR0kzMm5PbGRFakVOZW9leGRzUHI1V3RwdW8rMUhEMmF3cmlhbUhxTGtVeGorcTA2NAo0UDdhZlhxWjdlcHg2WjYxRHlDQ1BhUno0Tjk0V3cwc1BzTnZMVS95MitYOU1ZNnJxUEVENWlrTjVPSS9DUGIyCkYzOVVlSWhGeERtdHhST3JIL1ZJeGpmWVdHbElIRHU4UG50M2lxNnJ2VVZEL3Z2S0JqSFhMWnU2VHJxR0doMzcKUVVqbERxOXJxbm9aYW1Qb3A3Nk1laGlaSmdDYlQ1dkpnOWRkd1Z1VjdzdHg0RUFOOXF4Y0Nlck1lVkdMQXpnKwo0d1lyMkRubkc0dXBtMldwYXlOTHdrV0tYTFIzS0YvKy9aZWtuMVdKUzBYRERhaEtjRHpBbFE5SHgyR04KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
      },
      "properties": {
        "MainBoardBarcode": "T5691-M0001",
        "PowerBoardBarcode": "T5691-P001"
      }
    }
    
    HTTP_STATUS=201
    ===== HEADERS =====
    HTTP/1.1 201 Created
    Date: Mon, 15 Sep 2025 00:13:41 GMT
    Content-Type: application/json
    Content-Length: 12
    Connection: keep-alive
    apigw-requestid: Q6sIQg88IAMEJyg=
    ===== BODY =====
    {
      "id": 93285
    }
    registered_device_id=93285

</details>

Script (3) **. ./dev_reg_provision.sh**

<details>
<summary><h4>Details</h4></summary>
    pi@raspberrypi5:~/ioton $ . ./dev_reg_provision.sh 
    
    HTTP_STATUS=202
    ===== HEADERS =====
    HTTP/1.1 202 Accepted
    Date: Mon, 15 Sep 2025 00:15:12 GMT
    Content-Length: 0
    Connection: keep-alive
    apigw-requestid: Q6sWlgcsIAMEbkg=
    ===== BODY =====
    (empty)
</details>

Script (4) **. ./dev_reg_get_state.sh**

<details>
    <summary><h4>Details</h4></summary>
    pi@raspberrypi5:~/ioton $ . ./dev_reg_get_state.sh 
    
    HTTP_STATUS=200
    ===== HEADERS =====
    HTTP/1.1 200 OK
    Date: Mon, 15 Sep 2025 00:16:41 GMT
    Content-Type: application/json
    Content-Length: 563
    Connection: keep-alive
    apigw-requestid: Q6skciqjoAMEYcQ=
    ===== BODY =====
    {
      "id": 93285,
      "uuid": "IOTPAPPVIDEO0000009",
      "client_id": "multi-test-IOTPAPPVIDEO0000009",
      "customer_id": "multi-test",
      "firmware_version": null,
      "device_state": "PENDING",
      "created_date": 1757895221290,
      "flashed_date": null,
      "provisioning_certificate": {
        "certificate": null,
        "certificate_name": null,
        "certificate_authority_name": null,
        "certificate_link": "https://device-registry-prod-bucket.s3.amazonaws.com/IOTPAPPVIDEO0000009_null_null_IoT.ON.crt",
        "certificate_name_and_cert_authority_name": "null:null"
      },
      "properties": {},
      "ocpp_parameters": null,
      "parameters": {},
      "last_flashing": null
    }
    device_state=PENDING
    uuid=IOTPAPPVIDEO0000009
    certificate_link=https://device-registry-prod-bucket.s3.amazonaws.com/IOTPAPPVIDEO0000009_null_null_IoT.ON.crt
</details>


Script (5) **. ./dev_reg_get_events.sh**

<details>
    <summary><h4>Details</h4></summary>
    pi@raspberrypi5:~/ioton $ . ./dev_reg_events.sh 
    
    
    HTTP_STATUS=200
    ===== HEADERS =====
    HTTP/1.1 200 OK
    Date: Mon, 15 Sep 2025 00:17:25 GMT
    Content-Type: application/json
    Content-Length: 366
    Connection: keep-alive
    apigw-requestid: Q6srcj41oAMEYVA=
    ===== BODY =====
    [
      {
        "chip_id": "IOTPAPPVIDEO0000009",
        "type": "PENDING",
        "description": "Added to IoT.ON with PENDING condition",
        "customer_id": "multi-test",
        "timestamp": 1757895323485,
        "user_name": null
      },
      {
        "chip_id": "IOTPAPPVIDEO0000009",
        "type": "IMPORT_BOARD",
        "description": "Import new boards with specified Customer ID",
        "customer_id": "multi-test",
        "timestamp": 1757895221403,
        "user_name": "5190"
      }
]</details>



