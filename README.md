# pixiedust-notebook

# Overview

I wanted to check out Pixiedust and consider its utility for my data science work within the Openshift and Daikon tools. 

# Usage

1. Issue these commands from the command line (assuming you cloned/forked the repo already and have OpenShift set up)

`oc cluster up`

`oc new-app pixiedust-notebook.yaml`

2. Using a browser, go to the route created by the new-app command (localhost:8443 to get to the OpenShift console, then MyProject, then you'll see a URL for pixiedust-notebook towards the upper right)

3. When prompted for a password, the default is changeme. 

4. Once at the notebook directory structure, click upload

5. Select the Pixiedust On Openshift and Daikon.ipynb file

6. Click upload

7. Click on the resulting directory instance. 

8. Enjoy the contents of the Notebook!
