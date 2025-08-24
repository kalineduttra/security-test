# security-test

### **Header Security Test Automation**

A solution focused on evaluating the **implementation and integrity of web headers**, providing clear and accessible documentation for both technical professionals and non-technical stakeholders.

![Diagram](support/security-test-diagram.drawio.png)

### **Objective**

The primary objective is to verify and validate the correctness and effectiveness of the **security implementation of system headers**. When a weakness in these headers is identified, the solution helps in assessing the associated risk and provides clear guidance for implementing an improvement plan.

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

* **.github/workflows/:** used to automatically test the security headers of a web application.

* **support/:** Directory for support files

* **header-security-check.sh:** Executable script responsible for performing security checks on HTTP headers