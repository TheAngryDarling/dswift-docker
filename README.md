# Dynamic Swift for Docker
![Docker](https://img.shields.io/badge/platform-Docker-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)

#### A Docker image for [Dynamic Swift](https://github.com/TheAngryDarling/dswift)

    Note: This only supports Swift >= 4.0 that are not slim versions

## Usage

#### Pull the Docker image from Docker Hub

```bash
# pull the lastest version
docker pull theangrydarling/dswift
# pull a specific swift image version
docker pull theangrydarling/dswift:{swift version}
```

#### Create a container from the image and run it

```bash
docker run -it theangrydarling/dswift /bin/bash
docker run -it theangrydarling/dswift:{swift version} /bin/bash


# provides the access of the dswift config for the current user from the physical host into the container
docker run -it -v ~/.dswift.config:/root/.dswift.config theangrydarling/dswift:{swift version} /bin/bash

# runs the latest version with the current user dswift config
docker run -it -v ~/.dswift.config:/root/.dswift.config theangrydarling/dswift /bin/bash

# Add the user name and display name so when generating readme files they are properly added as author
# Mac:
docker run -it -v ~/.dswift.config:/root/.dswift.config -e REAL_USER_NAME="$(whoami)" -e REAL_DISPLAY_NAME="$(dscl . -read /Users/$(whoami) RealName | sed -n 's/^ //g;2p')" theangrydarling/dswift /bin/bash
# Linux:
docker run -it -v ~/.dswift.config:/root/.dswift.config -e REAL_USER_NAME="$(whoami)" -e REAL_DISPLAY_NAME="$(getent passwd $(whoami) | cut -d ':' -f 5 | cut -d ',' -f 1)" theangrydarling/dswift /bin/bash
```

#### dswift Config

This is an optional file used to provide extra features within dswift

```
{
    // The default swift path to use unless specificed in the command line
    "swiftPath": "/usr/bin/swift",

    // Sort files and folders within the project
    // "none":  No sorting
    // "sorted": Sort by name, folders first. Except for root, the root has files before folders and folders are in a special order, and Package.swift will always be at the top
    "xcodeResourceSorting": "none",

    // Auto create a license file for the project
    // "none": No license
    // "apache2_0": Apache License 2.0
    // "gnuGPL3_0": GNU GPLv3
    // "gnuAGPL3_0": GNU AGPLv3
    // "gnuLGPL3_0": GNU LGPLv3
    // "mozilla2_0": Mozilla Public License 2.0
    // "mit": MIT License
    // "unlicense": The Unlicense
    // address to file (Local path address, or web address)
    "license": "none",

    // The path the the specific read me files.  If set, and the file exists, it will be copied into the project replacing the standard one
    // Valid values are:
    //readme: "{path to read me file for all project types}" OR "generated"
    // OR
    // Please note, each property is optional
    // "readme": {
    //      "executable": "{path to read me file for all executable projects}" OR "generated",
    //      "library": "{path to read me file for all library projects}" OR "generated",
    //      "sysMod": "{path to read me file for all system-module projects}" OR "generated",
    // },

    // Author Name.  Used when generated README.me as the author name
    // If author name is not set, the application wil try and use env variable REAL_DISPLAY_NAME if set otherwise use the current use display name from the system
    // "authorName": "YOUR NAME HERE",

    // Regenerate Xcode Project (If already exists) when package is updated
    "regenerateXcodeProject": false,

    // Your public repositor information.  This is used when auto-generating readme files
    // "repository": "https://github.com/YOUR REPOSITORY" <-- Sets the Service URL and repository name
    // OR
    // Please note, serviceName and repositoryName are optional
    // "repository": {
    //      "serviceName": "GitHub",
    //      "serviceURL": "https://github.com/YOUR REPOSITORY",
    //      "repositoryName": "YOUR REPOSITORY NAME",
    // }
}
```

## Dependencies

* **[Swift](https://github.com/apple/swift)** - The Swift Programming Language
* **[Docker](https://www.docker.com)** - The container management/deployment system
* **[Swift for Docker](https://github.com/apple/swift-docker)** - Docker Official Image packaging for Swift
* **[Dynamic Swift](https://github.com/TheAngryDarling/dswift)** - Dynamic Swift. A way to generate dynamic swift code with the swift language

## Author

* **Tyler Anger** - *Initial work* - [TheAngryDarling](https://github.com/TheAngryDarling/)

## License

This project is licensed under Apache License v2.0 - see the [LICENSE.md](LICENSE.md) file for details.
