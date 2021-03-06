FROM centos:centos7

# Install GraalVM
RUN mkdir graalvm
RUN curl -s -L https://github.com/oracle/graal/releases/download/vm-1.0.0-rc12/graalvm-ce-1.0.0-rc12-linux-amd64.tar.gz | \
    tar zvx -C graalvm --strip-components 1

# Install Maven
RUN mkdir maven
RUN curl -s -L http://mirrors.ibiblio.org/apache/maven/maven-3/3.6.0/binaries/apache-maven-3.6.0-bin.tar.gz | \
    tar zvx -C maven --strip-components 1

# Add GraalVM to the path
ENV PATH="/graalvm/bin:${PATH}"
ENV JAVA_HOME="/graalvm"

# Install languages for GraalVM
RUN gu install python
RUN gu install ruby
RUN gu install r

# Git
RUN yum install -y git && yum clean all

ADD files/build.sh /build.sh
RUN /build.sh

WORKDIR /ksql

# Add ksql binaries to the path
ENV PATH="/ksql/bin:${PATH}"

# Remove maven
RUN rm -rf /maven

# Some env vars we might want to set when running the KSQL server
ENV BOOTSTRAP_SERVERS="localhost:9092"
ENV KSQL_LISTENERS="http://localhost:8088"

ADD docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["ksql-server-start", "/etc/ksql-server.properties"]
