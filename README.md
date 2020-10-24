# Warning: Pre-alpha version in active development - may not function as described below. 
*We expect to release a working version by the end of 2020.*

<p align="center">
    <a id="ibeam" href="#ibeam">
        <img src="https://github.com/Voyz/ibeam/blob/master/media/ibeam_logo.png" alt="IBeam logo" title="IBeam logo" width="600"/>
    </a>
</p>

<p align="center">
    <a href="https://opensource.org/licenses/Apache-2.0">
        <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg"/> 
    </a>
    <a href="https://github.com/Voyz/ibeam/releases">
        <img src="https://img.shields.io/pypi/v/ibeam?label=version"/> 
    </a>
</p>

IBeam is an authentication and maintenance tool used for the [Interactive Brokers Client Portal Web API Gateway.][gateway]

Features:

* **Facilitates continuous headless run of the Gateway.**

* **No physical display required** - virtual display buffer can be used instead.
* **No interaction from the user required** - automated injection of IBKR credentials into the authentication page used by the Gateway. 
* **Containerised using Docker** - it's a plug and play image, although IBeam can be used as standalone too.
* **Not so secure** - Yupp, you'll need to store the credentials somewhere, and that's a risk. Read more about it in [Security](#security).

Documentation:

* [Installation](#installation)
* [Startup](#startup)
* [Runtime environment requirements](#runtime-environment)
* [Security](#security)
* [How does IBeam work?](#how-ibeam-works)
* [Roadmap](#roadmap)

## Installation

Docker image (recommended):
```posh
docker pull voyz/ibeam
```

Standalone:
```posh
pip install ibeam
```

## Startup

### Using Docker image (recommended)

IBeam's Docker image is configured to work out of the box. Run the IBeam image exposing the port 5000 and providing the environment variable credentials either [directly or through a file][docker-envs].

Using env.list file:
```posh
docker run --env-file env.list -p 5000:5000 voyz/ibeam
```

Providing environment variables directly:
```posh
docker run --env IB_ACCOUNT=your_account123 --env IB_PASSWORD=your_password123 -p 5000:5000 voyz/ibeam
```

Verify the Gateway is running inside of the container by calling:
```posh
curl -X GET "https://localhost:5000/v1/api/one/user" -k
```

### Standalone 

The entrypoint of IBeam is the `ibeam_starter.py` script. When called without any arguments, the script will start the Gateway (if not currently running) and will attempt to authenticate (if not currently authenticated).

```posh
python ibeam_starter.py
```

Following exclusive flags can be provided when running the starter script:

* `-a`, `--authenticate` - Authenticate the currently running gateway.
* `-k`, `--kill` - Kill the gateway.
* `-m`, `--maintain` - Maintain the gateway.
* `-s`, `--start` - Start the gateway if not already running.
* `-t`, `--tickle` - Tickle the gateway.
* `-u`, `--user` - Get the user info.
* `-l`, `--validate` - Validate authentication.

Additionally the following flag can be supplied with any other flags to log additional runtime information:

* `-v`, `--verbose` - More verbose output.

Verify the Gateway is running as standalone by calling:
```posh
curl -X GET "https://localhost:5000/v1/api/one/user" -k
```

You will need additional environment requirements to run IBeam standalone. Read more about it in [Standalone Environment](#standalone-environment)

### Once started

Once the Gateway is running and authenticated you can communicate with it like you would normally. Please refer to [Interactive Brokers' documentation][gateway] for more.

## <a name="runtime-environment"></a>Runtime environment requirements

### Credentials
Whether running using an image or as standalone, IBeam expects IBKR credentials to be provided as environment variables. We recommend you start using IBeam with your [paper account credentials][paper-account], and only switch to production account once you're ready to trade.

* `IB_ACCOUNT` - IBKR account name 
* `IB_PASSWORD` - IBKR account password

IBeam expects an optional third credential `IB_KEY`. If provided, it will be used to decrypt the password given in the `IB_PASSWORD` variable. [cryptography.fernet][fernet] decryption is used, therefore to encrypt your password use:

```python
from cryptography.fernet import Fernet
key = Fernet.generate_key()
f = Fernet(key)
password = f.encrypt(b"your_ibkr_password123")
print(f'IB_PASSWORD={password}, IB_KEY={key}')
```

If any of the required credentials environment variables is not found, user will be prompted to enter them directly in the terminal.

### <a name="standalone-environment"></a>Standalone environment 

When running standalone, IBeam requires the following to be present:

* [IBKR Client Portal API Gateway][gateway]
* [Java JRE capable of running the Gateway][jre]
* [Google Chrome][chrome]
* [Chrome Driver][chrome-driver]

Additionally, the following environment variables:

* `CHROME_DRIVER_PATH` - path to the Chome Driver executable
* `GATEWAY_PATH` - path to the root of the Gateway 

Note that you can chose to not use the `ibeam_starter.py` script and instantiate and use the `ibeam.gateway_client.GatewayClient` directly in your script instead. This way you will be able to provide any of the credentials, as well as the Chrome Driver and Gateway paths directly upon construction of the `GatewayClient`.

### Optional environment variables

To facilitate custom usage and become more future-proof, IBeam expects the following environment variables altering its behaviour:


| Variable name | Default value | Description |
| ---  | ----- | --- |
| `GATEWAY_STARTUP_SECONDS` | 3 | How many seconds to wait before attempting to communicate with the gateway after  its startup. |
| `GATEWAY_BASE_URL` | `https://localhost:5000` | Base URL of the gateway. |
| `GATEWAY_PROCESS_MATCH` | ibgroup.web.core.clientportal.gw.GatewayStart | The gateway process' name to match against |
| `ROUTE_AUTH` | /sso/Login?forwardTo=22&RL=1&ip2loc=on | Gateway route with authentication page.
| `ROUTE_USER` | /v1/api/one/user | Gateway route | with user information. |
| `ROUTE_VALIDATE` | /v1/portal/sso/validate | Gateway route with validation call. |
| `ROUTE_TICKLE` | /v1/api/tickle | Gateway route with tickle call. |
| `USER_NAME_EL_ID` | user_name | HTML element id containing the username input field. |
| `PASSWORD_EL_ID` | password | HTML element id containing the password input field. |
| `SUBMIT_EL_ID` | submitForm | HTML element id containing the submit button. |
| `SUCCESS_EL_TEXT` | Client login succeeds | HTML element text indicating successful authentication. |
| `MAINTENANCE_INTERVAL` | 60 | How many seconds between each maintenance. |
| `LOG_LEVEL` | INFO | Verbosity level of the logger used. |

## <a name="security"></a>Security
Please feel free to suggest improvements to the security risks currently present in IBeam and the Gateway by [opening an issue][issues] on GitHub.

### Credentials

The Gateway requires credentials to be provided on a regular basis. The only way to avoid manually having to input them every time is to store the credentials somewhere. This alone is a security risk.

Currently, IBeam expects the credentials to be available as environment variables during runtime. Whether running IBeam in a container or directly on a host machine, an unwanted user may gain access to these credentials. If your setup is exposed to a risk of someone unauthorised reading the credentials, you may want to look for other solutions than IBeam or use the Gateway standalone and authenticate manually each time.

We considered providing a possibility to read the credentials from an external credentials store, such as GCP Secrets, yet that would require some authentication credentials too, which brings back the same issue it was to solve.

### Certificates

Certificates support is currently in development.


## <a name="how-ibeam-works"></a>How does IBeam work?

In a standard startup IBeam performs the following:

1. **Ensure the Gateway is running** by calling the tickle endpoint. If not:
    1. Start the Gateway in a new shell.
1. **Ensure the Gateway is authenticated** by calling the validation endpoint. If not:
    1. Create a new Chrome Driver instance using `selenium`.
    1. Start a virtual display using `pyvirtualdisplay`.
    1. Access the Gateway's authentication website.
    1. Once loaded, input username and password and submit the form.
    1. Wait for the login confirmation and quit the website.
    1. Verify once again if Gateway is running and authenticated.
1. **Start the maintenance**, attempting to keep the Gateway alive and authenticated.


## Roadmap

IBeam was built by traders just like you. We made it open source in order to collectively build a reliable solution. If you enjoy using IBeam, we encourage you to attempt implementing one of the following tasks:

* ~~Include TLS certificates.~~
* Remove necessity to install Java.
* Remove necessity to install Chrome or find a lighter replacement.
* Add usage examples.
* Full test coverage.
* Improve the security issues.

Read the [CONTRIBUTING](https://github.com/Voyz/ibeam/blob/master/CONTRIBUTING.md) guideline to get started.

----

## Licence

See [LICENSE](https://github.com/Voyz/ibeam/blob/master/LICENSE)



## Disclaimer

IBeam is not built, maintained, or endorsed by the Interactive Brokers. 

Use at own discretion. IBeam and its authors give no guarantee of uninterrupted run of and access to the Interactive Brokers Client Portal Web API Gateway. You should prepare for breaks in connectivity to IBKR servers and should not depend on continuous uninterrupted run of the Gateway. IBeam requires your private credentials to be exposed to a security risk, potentially resulting in, although not limited to interruptions, loss of capital and loss of access to your account. To partially reduce the potential risk use Paper Account credentials.

IBeam is provided on an AS IS and AS AVAILABLE basis without any representation or endorsement made and without warranty of any kind whether express or implied, including but not limited to the implied warranties of satisfactory quality, fitness for a particular purpose, non-infringement, compatibility, security and accuracy.  To the extent permitted by law, IBeam's authors will not be liable for any indirect or consequential loss or damage whatever (including without limitation loss of business, opportunity, data, profits) arising out of or in connection with the use of IBeam.  IBeam's authors make no warranty that the functionality of IBeam will be uninterrupted or error free, that defects will be corrected or that IBeam or the server that makes it available are free of viruses or anything else which may be harmful or destructive.

[issues]: https://github.com/Voyz/ibeam/issues
[fernet]: https://cryptography.io/en/latest/fernet/
[gateway]: https://interactivebrokers.github.io/cpwebapi/
[jre]: https://www.java.com/en/download/
[chrome]: https://www.google.com/chrome/
[chrome-driver]: https://chromedriver.chromium.org/downloads
[docker-envs]: https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file
[paper-account]: https://guides.interactivebrokers.com/am/am/manageaccount/aboutpapertradingaccounts.htm