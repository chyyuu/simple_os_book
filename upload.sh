#!/bin/bash
ls -al *.pdf
pdfv1=`git config remote.origin.url`
pdfv2=${pdfv1#*github.com/}
pdfname=${pdfv2%/*}_kaiyuanbook.zh.pdf
echo $pdfv1 $pdfv2 $pdfname
env
cp id_rsa_mkbok ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
cat ~/.ssh/known_hosts
echo "repo.or.cz,195.113.20.142 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAs7JJacVNc1wk/6RZqMHin5RwR/LdIcMGGeG6WG4Sl/wETY9KYUVd126Yb2MV7vBT/8dW0iE6u6+sRVM3Xn5MG9K2PvQ57SbIQ53FvR4qBCqYkSn5sKs2wt9GpXh2MFN5TuXth2d1BABSR2a1u461K8SKbhclPVeFCeligaI4lGc=" >> ~/.ssh/known_hosts
cat ~/.ssh/known_hosts
git clone ssh://mkbok@repo.or.cz/srv/git/mkbok.git mkbok.pdf
cd mkbok.pdf
ls -al
cp ../kaiyuanbook.zh.pdf $pdfname
git add $pdfname
git config user.name "Larry Cai"
git config user.email "larry.caiyu@gmail.com"
git commit -am "add file"
git push origin master