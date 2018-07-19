FROM node
MAINTAINER ZHANGZHANQI <zhangzhanqicixi@gmail.com>
WORKDIR /app
# install hexo
RUN npm install hexo-cli -g
RUN hexo init .
RUN npm install
# install apollo deploy
RUN npm install --save hexo-renderer-jade hexo-generator-feed hexo-generator-sitemap hexo-generator-archive
COPY _config.yml .
COPY ./source/_posts ./source/_posts
COPY ./themes/apollo ./themes/apollo
CMD ["hexo", "s", "-l"]