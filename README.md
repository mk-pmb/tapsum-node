﻿
<!--#echo json="package.json" key="name" underline="=" -->
tapsum
======
<!--/#echo -->

<!--#echo json="package.json" key="description" -->
A bash script to summarize errors from the `tap` package.
<!--/#echo -->


<!--#include file="tapsum.sh" start="  local HELP=&quot;" stop="    &quot;"
  outdent="    " code="text" -->
<!--#verbatim lncnt="19" -->
```text
tapsum: run selected tests, log the result, and summarize it.

Invocation:
  * $INVO --help
    Show this summary.
  * $INVO
    Run all tests and show an overall summary.
  * $INVO 304
    Run test/304.js and show its error summary.
  * $INVO --sumerr 304.tap.err
    Summarize the errors of test's last recording.
  * $INVO --sumerr
    Summarize errors of all recorded test results.
  * $INVO --sumerr 304.tap.err
    Summarize errors of this test's last recording.
  * $INVO --versions
    Show versions of node, npm, linux distro and the git HEAD hash.
```
<!--/include-->



<!--#toc stop="scan" -->



Known issues
------------

* Needs more/better tests and docs.




&nbsp;


License
-------
<!--#echo json="package.json" key=".license" -->
ISC
<!--/#echo -->
