# security-test

### **Header Security Test Automation**

A solution focused on evaluating the implementation and integrity of web headers, providing clear and accessible documentation for both technical professionals and non-technical stakeholders.

![Diagram](support/security-test-diagram.drawio.png)

### **Objective**

The primary objective is to verify and validate the correctness and effectiveness of the security implementation of system headers. When a weakness in these headers is identified, the solution helps in assessing the associated risk and provides clear guidance for implementing an improvement plan.

### **Structure**

```shell
    $ tree
    .
    ├── .github/
    │    └── workflows/
    │        └── security-headers-test.yaml
    ├── support
    └── header-security-check.sh
```

* **.github/workflows/:** It will automatically fire on push and pull request events. The pipeline checks the code, runs the `header-security-check.sh` script at the specified URL and generates a PDF report inside a Docker container using a latex image for better formatting.

* **support/:** Directory for support files

* **header-security-check.sh:** Executable script responsible for performing security checks on HTTP headers