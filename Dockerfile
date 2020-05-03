FROM debian:latest

WORKDIR /root

RUN apt-get update -yq
RUN apt-get install -yq openjdk-11-jdk wget ssh python3.7 python3-pip
RUN apt-get clean -y

RUN wget http://apache.crihan.fr/dist/spark/spark-3.0.0-preview2/spark-3.0.0-preview2-bin-hadoop3.2.tgz -q -P /opt/
RUN tar -xzf /opt/spark-3.0.0-preview2-bin-hadoop3.2.tgz -C /opt/ && rm /opt/spark-3.0.0-preview2-bin-hadoop3.2.tgz

RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-3.2.1/hadoop-3.2.1.tar.gz -q -P /opt/
RUN tar -xzf /opt/hadoop-3.2.1.tar.gz -C /opt/ && rm /opt/hadoop-3.2.1.tar.gz

RUN ssh-keygen -t rsa -P '' -f /root/.ssh/id_rsa
RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
RUN chmod 0600 /root/.ssh/authorized_keys

RUN echo '<configuration><property><name>fs.defaultFS</name><value>hdfs://0.0.0.0:9000</value></property><property><name>hadoop.tmp.dir</name><value>/opt/data/</value></property></configuration>' > /opt/hadoop-3.2.1/etc/hadoop/core-site.xml
RUN echo '<configuration><property><name>dfs.replication</name><value>1</value></property></configuration>' > /opt/hadoop-3.2.1/etc/hadoop/hdfs-site.xml
RUN echo '<configuration><property><name>mapreduce.framework.name</name><value>yarn</value></property></configuration>' > /opt/hadoop-3.2.1/etc/hadoop/mapred-site.xml
RUN echo '<configuration><property><name>yarn.nodemanager.aux-services</name><value>mapreduce_shuffle</value></property></configuration>' > /opt/hadoop-3.2.1/etc/hadoop/yarn-site.xml

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1
RUN pip3 install notebook findspark pandas numpy azureml-sdk azureml-sdk[automl,notebooks]

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV HADOOP_HOME=/opt/hadoop-3.2.1
ENV SPARK_HOME=/opt/spark-3.0.0-preview2-bin-hadoop3.2
ENV PATH=$PATH:$HADOOP_HOME/bin
ENV PATH=$PATH:$HADOOP_HOME/sbin
ENV PATH=$PATH:$SPARK_HOME/bin
ENV PATH=$PATH:$SPARK_HOME/sbin
ENV HDFS_NAMENODE_USER=root
ENV HDFS_DATANODE_USER=root
ENV HDFS_SECONDARYNAMENODE_USER=root
ENV YARN_RESOURCEMANAGER_USER=root
ENV YARN_NODEMANAGER_USER=root

RUN wget https://repo1.maven.org/maven2/javax/activation/activation/1.1.1/activation-1.1.1.jar -q -P /opt/hadoop-3.2.1/share/hadoop/yarn

RUN echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> /opt/hadoop-3.2.1/etc/hadoop/hadoop-env.sh

RUN mkdir /opt/data
RUN /opt/hadoop-3.2.1/bin/hdfs namenode -format

EXPOSE 8888 9870 9000 8080 8088

CMD /etc/init.d/ssh restart && start-dfs.sh && start-yarn.sh && start-master.sh && start-slave.sh spark://127.0.0.1:7077 && jupyter notebook --ip=0.0.0.0 --allow-root
