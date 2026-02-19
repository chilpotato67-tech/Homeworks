FROM public.ecr.aws/amazonlinux/amazonlinux:2023

RUN dnf -y install httpd && dnf clean all
RUN echo "Hello from ECR homework" > /var/www/html/index.html

EXPOSE 80
CMD ["/usr/sbin/httpd","-D","FOREGROUND"]
