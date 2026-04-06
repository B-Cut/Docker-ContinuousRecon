# Install go packages firts
FROM golang:latest AS go-build

RUN go install github.com/tomnomnom/waybackurls@latest && cp $GOPATH/bin/waybackurls /usr/local/bin
RUN go install github.com/d3mondev/puredns/v2@latest && cp $GOPATH/bin/puredns /usr/local/bin
RUN go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest && cp $GOPATH/bin/httpx /usr/local/bin/httpx

# Despite the necessary services being quite few, i will use the kali image at first for convenience
FROM kalilinux/kali-rolling AS kali-build

EXPOSE 1337

RUN apt update 
RUN apt -y install \
    python3 \
    python3-flask \
    python3-dotenv \
    python3-jsbeautifier \
    python3-setuptools \
    amass \
    subfinder \
    assetfinder \
    findomain \
    curl \
    jq \
    massdns \
    masscan \
    ffuf \
    getallurls \
    golang \
    git \
    wget \
    trufflehog 

COPY --from=go-build /usr/local/bin/waybackurls /usr/local/bin/waybackurls
COPY --from=go-build /usr/local/bin/puredns /usr/local/bin/puredns
COPY --from=go-build /usr/local/bin/httpx /usr/local/bin/httpx

RUN git clone https://github.com/GerbenJavado/LinkFinder /opt/LinkFinder \
    && cd /opt/LinkFinder \
    && python3 setup.py install

# Get necessary wordlists

RUN mkdir /wordlists

RUN wget \
    https://raw.githubusercontent.com/danielmiessler/SecLists/refs/heads/master/Discovery/Web-Content/raft-large-words.txt \
    -P /wordlists

RUN wget \
    https://github.com/trickest/resolvers/raw/refs/heads/main/resolvers.txt \
    -P /wordlists

# Copy necessary files
# We don't want the final image to have the .env file once built due to the sensitive nature of it's contents
COPY ./C2C.py /C2C.py
COPY ./recon_scripts /recon_scripts

RUN chmod +x -r /recon_scripts




# TODO: Migrate to proper wsgi server once this is hosted on the internet
#CMD ["flask","--app", "C2C", "run", "--port=1337"]
