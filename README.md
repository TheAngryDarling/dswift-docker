# Dynamic Swift for Docker

![Docker](https://img.shields.io/badge/platform-Docker-green.svg?style=flat)
![Apache 2](https://img.shields.io/badge/license-Apache2-blue.svg?style=flat)

#### A Docker image for [Dynamic Swift](https://github.com/TheAngryDarling/dswift)

Note: This only supports Swift >= 4.0 that are not slim versions

## Usage

### Pull the Docker image from Docker Hub

```bash
# pull the lastest version
docker pull theangrydarling/dswift
# pull a specific swift image version
docker pull theangrydarling/dswift:{swift version}
```

### Create a container from the image and run it

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

### Running

```bash
# Create new package
dswift package init --type {package type}

# Build package
dswift build
dswift build -c {configuration name: debug, release}

# Clean project
dswift package clean

# Generate Xcode Project
dswift package generate-xcodeproj
```

### File Formats

#### Dynamic Swift Files (dswift)

Files that work a lot like ASP or JSP files which use swift as the programming language and expect swift as the output

Test File named test.dswift

```swift
// Some comment

import Foundation

public class NewClass {
    <% let types: [String] = ["Int", "Int8", "Int16", "Int32", "Int64"] %>
    <% for t in types { %>
    func print(_ value: <%=t%>) {
        print("<%=t%> \(t)")
    }
    <%}%>
}
```

Generated file named test.swift

```swift
//  This file was dynamically generated from 'test.dswift' by Dynamic Swift.  Please do not modify directly.
//  Dynamic Swift can be found at https://github.com/TheAngryDarling/dswift.

// Some Comment

import Foundation

public class NewClass {
    func print(_ value: Int) {
        print("Int \(t)")
    }
    func print(_ value: Int8) {
        print("Int8 \(t)")
    }
    func print(_ value: Int16) {
        print("Int16 \(t)")
    }
    func print(_ value: Int32) {
        print("Int32 \(t)")
    }
    func print(_ value: Int64) {
        print("Int64 \(t)")
    }
}
```

#### Dynamic Swift Static Files (dswift-static)

A JSON file that tells dswift what file to load and how to build it in

#### Files containing text

The type field is set to text.  If a specific String encoding is required, you can specify the IANA Character set in the field as follows: "type": "text(utf8)" or "text(utf16)" or "text(ascii)".  By default the loader will use utf8 if no IANA Character set is provided

Test file teststring.dswift-static importing file File.strings as an extension

```JSON
{
    "file": "File.strings",
    "namespace": "ClassName1.ClassName2",
    "modifier": "public",
    "name": "Strings",
    "type": "text"
}
```

Generated file teststring.swift

```swift
//  This file was dynamically generated from 'teststring.dswift-static' and 'File.strings' by Dynamic Swift.  Please do not modify directly.
//  Dynamic Swift can be found at https://github.com/TheAngryDarling/dswift.

public extension ClassName1.ClassName2 {
    struct Strings {
        private init() { }
        public static let string: String = """
...
"""
        public static var data: Data { return Strings.string.data(using: String.Encoding(rawValue: 4))! }
    }
}
```

Generated file teststring.swift where dswift-static file does not have a namespace

```swift
//  This file was dynamically generated from 'teststring.dswift-static' and 'File.strings' by Dynamic Swift.  Please do not modify directly.
//  Dynamic Swift can be found at https://github.com/TheAngryDarling/dswift.


public struct Strings {
    private init() { }
    public static let string: String = """
...
"""
    public static var data: Data { return Strings.string.data(using: String.Encoding(rawValue: 4))! }
}
```

#### Files containing binary

Test file testbinary.dswift-static importing file File.binary as an extension

```JSON
{
    "file": "File.binary",
    "namespace": "ClassName1.ClassName2",
    "modifier": "public",
    "name": "Binary",
    "type": "binary"
}
```

Generated file testbinary.swift

```swift
//  This file was dynamically generated from 'testbinary.dswift-static' and 'File.binary' by Dynamic Swift.  Please do not modify directly.
//  Dynamic Swift can be found at https://github.com/TheAngryDarling/dswift.

public extension ClassName1.ClassName2 {
    struct Binary {
        private init() { }
        private static var _value: [UInt8] = [
            ...
        ]
        public static var data: Data { return Data(bytes: Binary._value) }
    }
}
```

Generated file testbinary.swift where dswift-static file does not have a namespace

```swift
//  This file was dynamically generated from 'testbinary.dswift-static' and 'File.binary' by Dynamic Swift.  Please do not modify directly.
//  Dynamic Swift can be found at https://github.com/TheAngryDarling/dswift.


public struct Binary {
    private init() { }
    private static var _value: [UInt8] = [
            ...
        ]
    public static var data: Data { return Data(bytes: Binary._value) }
}
```

### dswift Config

This is an optional file used to provide extra features within dswift
If the dswift config does not already exists you can execute 'dswift --config' to generate the default configuration.  It will be located at at ~/.dswift.config

```json
{
    // (Optional, If not set /usr/bin/swift is used) The default swift path to use unless specificed in the command line
    // "swiftPath": "/usr/bin/swift",

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
    //      "system-module": "{path to read me file for all system-module projects}" OR "generated",
    //      "other project type": "{path to read me file for other project type}" OR "generated",
    //      "default": "{path to read me file for all other project types}" OR "generated",
    // },

    // Author Name.  Used when generated README.md as the author name
    // If author name is not set, the application wil try and use env variable REAL_DISPLAY_NAME if set otherwise use the current use display name from the system
    // "authorName": "YOUR NAME HERE",

    // Provides an indicator of when to add the build rules to the Xcode Project.
    //      always: Even if there are no custom build files
    //      whenNeeded: Only when there are custom build files
    // "whenToAddBuildRules": "always" OR "whenNeeded",

    // (Optional, Default: false) Generate Xcode Project on package creation if the flag is true
    // "generateXcodeProjectOnInit": true,
    // "generateXcodeProjectOnInit": {
    //      "library": true,
    //      "executable": true,
    //      "system-module": true,
    //      "other project type": true,
    //      "default": true,
    // },

    // Regenerate Xcode Project (If already exists) when package is updated
    "regenerateXcodeProject": false,

    // Your public repositor information.  This is used when auto-generating readme files
    // "repository": "https://github.com/YOUR REPOSITORY", <-- Sets the Service URL and repository name
    // OR
    // Please note, serviceName and repositoryName are optional
    // "repository": {
    //      "serviceName": "GitHub",
    //      "serviceURL": "https://github.com/YOUR REPOSITORY",
    //      "repositoryName": "YOUR REPOSITORY NAME",
    // },

    // (Optional, Default: true) Lock generated files from being modified manually
    // "lockGenratedFiles": true,

    // (Optional, Default: false) Indicator if generated files should be kepted in Xcode Project when generating / updating project
    // "includeGeneratedFilesInXcodeProject": false,

    // (Optional, Default: never) Indicator if, when generating Xcode Project file, the application should install SwiftLint Build Phase Run Script if SwiftLint is installed.  Options: always, whenAvailable, never
    // "includeSwiftLintInXcodeProject": "never",

    // (Optional, Default: false) Indicator if we should try to auto install any missing system packages from the package manager
    // when requirements are found within the project, otherwise we will just give a warning.
    // Note: If dswift was built with the flag AUTO_INSTALL_PACKAGES.  This property is always true no matter what the configuration value is set to
    // "autoInstallMissingPackages": false,
    
    // (Optional, Default: null/nil) Provides an option to override the default gitignore contents that dswift generates
    // "defaultGitIgnore": {
    //      "items": [
    //          "Rule",
    //          "# Comment",
    //      ],
    //      "sections": [
    //          {
    //              "name": "Section Name",
    //              "description": [
    //                  "Description array separated by lines",
    //              ],
    //              "items": [
    //                  "Rule",
    //                  "# Comment",
    //              ],
    //              subsections: [
    //                  {
    //                      "name": "Sub Section Name",
    //                      "items": [
    //                          "Rule",
    //                          "# Comment",
    //                      ],
    //                  },
    //              ]
    //          },
    //      ]
    // },

    // (Optional, Default: null/nil) Provides an option to add additional items to the gitignore.
    // This structure is the same as defaultGitIgnore.  This object will be combined with the
    // default gitignore in the following way:
    // 1. All comments are ignored.
    // 2. I will first try and and see if the rule exists somewhere else before adding
    // 3. If the default gitignore has the same section with no description, the addition description will
    //   be copied
    // 4. Any sections/subsections that become empty due to rules already existing will not be added
    
    // "gitIgnoreAdditions": {
    //      "items": [
    //          "Rule",
    //      ],
    //      "sections": [
    //          {
    //              "name": "Section Name",
    //              "description": [
    //                  "Description array separated by lines",
    //              ],
    //              "items": [
    //                  "Rule",
    //              ],
    //              subsections: [
    //                  {
    //                      "name": "Sub Section Name",
    //                      "items": [
    //                          "Rule",
    //                      ],
    //                  },
    //              ]
    //          },
    //      ]
    // },
}
```

## Dependencies

* **[Swift](https://github.com/apple/swift)** - The Swift Programming Language
* **[Docker](https://www.docker.com)** - The container management/deployment system
* **[Swift for Docker](https://github.com/apple/swift-docker)** - Docker Official Image packaging for Swift
* **[Docker Hub List]https://github.com/TheAngryDarling/swift-docker)** - Docker Hub List application for getting list of tags from docker repositories
* **[Dynamic Swift](https://github.com/TheAngryDarling/dswift)** - Dynamic Swift. A way to generate dynamic swift code with the swift language

## Author

* **Tyler Anger** - *Initial work* - [TheAngryDarling](https://github.com/TheAngryDarling/)

## License

This project is licensed under Apache License v2.0 - see the [LICENSE.md](LICENSE.md) file for details.
