<h1>A bash utility to support the device registry API</h1>

<details>
  <summary><h2>Certificate background</h2></summary>
  A query to the manufacturer backend (environment ID/customer ID) will produce the following:
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
</detail>
