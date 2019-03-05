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

# Clone the POC branch
RUN yum install -y git && yum clean all
RUN git clone -b feature-multilingual-udfs \
    https://github.com/mitch-seymour/ksql.git \
    /ksql

WORKDIR /ksql

# Build ksql
RUN cd /ksql && \
    time /maven/bin/mvn package -DskipTests | grep "Building.*[\d\+/\d\+\]\\|SUCCESS"

# Add ksql binaries to the path
ENV PATH="/ksql/bin:${PATH}"

# Remove maven
RUN rm -rf /maven

# Install languages for GraalVM
RUN gu install python
RUN gu install ruby

CMD ["ksql-server-start", "config/ksql-server.properties"]
