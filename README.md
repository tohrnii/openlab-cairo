# Openlab cairo

Work in progress naive poc of openlab in cairo

Users can submit a series of jobs in a pipeline. Each job has a payment attached in any ERC20 token and a deadline to complete the job. The next job in the pipeline can only begin after the previous is completed. Jobs are stored as a doubly linked list.  
This poc has a series of reverse complement calculation jobs for demonstration.

## getting started 
* make sure [open zeppelin nile](https://github.com/OpenZeppelin/nile) and [pytest](https://docs.pytest.org/en/7.1.x/getting-started.html) are installed.

```
pip3 install cairo-nile
pip3 install -U pytest
```
