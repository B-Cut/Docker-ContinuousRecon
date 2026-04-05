# Install go packages firts
FROM golang:latest AS go-build

RUN go install github.com/tomnomnom/waybackurls@latest && cp $GOPATH/bin/waybackurls /usr/local/bin
RUN go install github.com/d3mondev/puredns/v2@latest && cp $GOPATH/bin/puredns /usr/local/bin


# Despite the necessary services being quite few, i will use the kali image at first for convenience
FROM kalilinux/kali-rolling AS kali-build

# Setup wordlists

EXPOSE 1337

RUN apt update 
RUN apt -y install \
    python3 \
    python3-flask \
    python3-dotenv \
    httpx-toolkit \
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

RUN git clone https://github.com/GerbenJavado/LinkFinder /opt/LinkFinder \
    && cd /opt/LinkFinder \
    && python3 setup.py install

RUN mkdir wordlists
RUN wget \
    https://raw.githubusercontent.com/danielmiessler/SecLists/refs/heads/master/Discovery/Web-Content/raft-large-words.txt \
    -P $HOME/wordlists

COPY . /

# TODO: Migrate to proper wsgi server once this is hosted on the internet
CMD ["flask", "run", "--app", "C2C", "--port=1337"]
