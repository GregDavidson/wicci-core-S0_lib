# The Wicci System

The Wicci System is a collaborative content management system.  It consists of twelve extensive components which have each been given their own git repository to allow them to be reused more flexibly.  All components should be checked out and linked together appropriately before trying to build the Wicci System.

| REPOSITORY | DESCRIPTION
|---------------|----------
| [Wicci Core](https://github.com/GregDavidson/wicci-core-S0_lib) | The Heart of the Wicci System
| | Includes low-level C & SQL libraries and SQL Metaprogramming Foundation
| [SQL Schema 1: Refs](https://github.com/GregDavidson/wicci-core-S1_resf) | Server Programming eXtensions including
| | Refs = Typed Object References, Operations and Methods
| [SQL Schema 2: Core](https://github.com/GregDavidson/wicci-core-S2_core) | Ref Types for Unique Names and Environment Contexts
| [SQL Schema 3: More](https://github.com/GregDavidson/wicci-core-S3_more) | Ref Types for Arrays, Texts & Scalars
| [SQL Schema 4: Doc](https://github.com/GregDavidson/wicci-core-S4_doc) | Ref Types for Hierarchical Documents
| [SQL Schema 5: XML](https://github.com/GregDavidson/wicci-core-S5_xml) | Ref Types for URIs, XML and HTML
| [SQL Schema 6: HTTP](https://github.com/GregDavidson/wicci-core-S6_http) | Ref Types for HyperText
| [SQL Schema 7: Wicci](https://github.com/GregDavidson/wicci-core-S7_wicci) | the Wicci Server Model
| XFiles - coming soon | Multimedia files to load into Wicci Documents
| [Tools](https://github.com/GregDavidson/wicci-tools)	| Wicci utility programs (mostly scripts)
| [Docs](https://github.com/GregDavidson/wicci-doc)	| Documentation on the Wicci outside of the Wicci
| [The Wicci Shim](https://github.com/GregDavidson/wicci-shim-rust) | Reverse Proxy for Wicci HTTP Server
