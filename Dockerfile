# (ideally) minimal pyspark/jupyter notebook

# To create a spark 2.0.2 version (permits the Pixiedust Spark Job Progress bar) uncomment the below line and comment the line after it
#FROM eldritchjs/openshift-spark2.0.2
FROM radanalyticsio/openshift-spark

USER root

## taken/adapted from jupyter dockerfiles

# Not essential, but wise to set the lang
# Note: Users with other languages should set this in their derivative image
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV PYTHONIOENCODING UTF-8
ENV CONDA_DIR /opt/conda
ENV NB_USER=nbuser
ENV NB_UID=1011
ENV NB_PYTHON_VER=2.7

COPY requirements.txt /tmp/

# Python binary and source dependencies
RUN yum install -y curl wget java-headless bzip2 gnupg2 sqlite3 \
    && yum clean all -y \
    && cd /tmp \
    && wget -q https://repo.continuum.io/miniconda/Miniconda3-4.2.12-Linux-x86_64.sh \
    && echo d0c7c71cc5659e54ab51f2005a8d96f3 Miniconda3-4.2.12-Linux-x86_64.sh | md5sum -c - \
    && bash Miniconda3-4.2.12-Linux-x86_64.sh -b -p $CONDA_DIR \
    && rm Miniconda3-4.2.12-Linux-x86_64.sh \
    && export PATH=/opt/conda/bin:$PATH \
    && yum install -y gcc gcc-c++ glibc-devel git \
    && /opt/conda/bin/conda install --quiet --yes python=$NB_PYTHON_VER 'nomkl' \
			    'ipywidgets' \
			    'matplotlib' \
			    'scipy' \
			    'seaborn' \
			    'cloudpickle' \
			    statsmodels \
			    pandas \
			    'dill' \
			    notebook \
			    jupyter \
    && /opt/conda/bin/conda install jupyter_dashboards -c conda-forge \
    && pip install widgetsnbextension \
    && pip install -r /tmp/requirements.txt \
    && yum erase -y gcc gcc-c++ glibc-devel \
    && yum clean all -y \
    && rm -rf /root/.npm \
    && rm -rf /root/.cache \
    && rm -rf /root/.config \
    && rm -rf /root/.local \
    && rm -rf /root/tmp \
    && useradd -m -s /bin/bash -N -u $NB_UID $NB_USER \
    && usermod -g root $NB_USER \
    && chown -R $NB_USER $CONDA_DIR \
    && conda remove --quiet --yes --force qt pyqt \
    && conda remove --quiet --yes --force --feature mkl ; conda clean -tipsy

RUN wget https://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo \
	&& sed -i s/\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo \
	&& yum install -y apache-maven

ENV PATH /opt/conda/bin:$PATH

ENV SPARK_HOME /opt/spark

USER $NB_UID

ENV SPARK_HOME /opt/spark

RUN mkdir -p /home/$NB_USER/pixiedust/bin

RUN wget --quiet https://github.com/cloudant-labs/spark-cloudant/releases/download/v2.0.0/cloudant-spark-v2.0.0-185.jar && mv cloudant-spark-v2.0.0-185.jar /home/$NB_USER/pixiedust/bin

RUN jupyter pixiedust install --silent; exit 0

USER root

ENV PIXIEDUST_HOME /home/$NB_USER/pixiedust

ENV SCALA_HOME $PIXIEDUST_HOME/bin/scala/scala-2.11.8
# Add a notebook profile.

RUN mkdir /notebooks && chown $NB_UID:root /notebooks && chmod 1777 /notebooks

EXPOSE 8888

RUN mkdir -p -m 700 /home/$NB_USER/.jupyter/ && \
    echo "c.NotebookApp.ip = '*'" >> /home/$NB_USER/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.open_browser = False" >> /home/$NB_USER/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.notebook_dir = '/notebooks'" >> /home/$NB_USER/.jupyter/jupyter_notebook_config.py && \
    chown -R $NB_UID:root /home/$NB_USER && \
    chmod g+rwX,o+rX -R /home/$NB_USER

LABEL io.k8s.description="PySpark Jupyter Notebook." \
      io.k8s.display-name="PySpark Jupyter Notebook." \
      io.openshift.expose-services="8888:http"

ENV TINI_VERSION v0.9.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc /tini.asc
#RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 0527A9B7 && gpg --verify /tini.asc
RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 0527A9B7 && gpg --verify /tini.asc
ADD start.sh /start.sh

RUN chmod +x /tini /start.sh


ENV HOME /home/$NB_USER
USER $NB_UID
COPY remotecache.py /home/$NB_USER
COPY remotecache.py /notebooks
COPY unsigned.py /home/$NB_USER
COPY unsigned.py /noteboooks
COPY amqp.py /notebooks
COPY amqp.py /home/$NB_USER/
COPY spark-streaming-amqp_2.11-0.3.2-SNAPSHOT.jar $SPARK_HOME/jars

WORKDIR /home/$NB_USER
RUN pip wheel infinispan -w . \
&& mv infinispan*.whl infinispan.zip

RUN pip wheel psycopg2 -w . \
&& mv psycopg2*.whl psycopg2.zip

WORKDIR /notebooks

ENTRYPOINT ["/tini", "--"]

CMD ["/entrypoint", "/start.sh"]
