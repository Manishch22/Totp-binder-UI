FROM node:12.18.4-alpine as build

# Set a build-time environment variable
ARG mockRpUIPublicUrl
ARG esignet_ui_base_url
ARG mock_relying_party_server_url
ARG redirect_uri
ARG redirect_uri_registration
ARG client_id
ARG acrs
ARG sign_in_button_plugin_url
ARG display
ARG prompt
ARG grant_type
ARG max_age
ARG claims_locales
ARG scope_user_profile

ENV ESIGNET_UI_BASE_URL=$esignet_ui_base_url
ENV MOCK_RELYING_PARTY_SERVER_URL=$mock_relying_party_server_url
ENV REDIRECT_URI=$redirect_uri
ENV REDIRECT_URI_REGISTRATION=$redirect_uri_registration
ENV CLIENT_ID=$client_id
ENV ACRS=$acrs
ENV SIGN_IN_BUTTON_PLUGIN_URL=$sign_in_button_plugin_url
ENV DISPLAY=$display
ENV PROMPT=$prompt
ENV GRANT_TYPE=$grant_type
ENV MAX_AGE=$max_age
ENV CLAIMS_LOCALES=$claims_locales
ENV SCOPE_USER_PROFILE=$scope_user_profile
ENV MOCK_RP_UI_PUBLIC_URL=$mockRpUIPublicUrl

# Set the environment variable as a placeholder for PUBLIC_URL
ENV PUBLIC_URL=_PUBLIC_URL_

## Mock relying party portal
WORKDIR ./app
COPY package*.json ./
RUN npm install
COPY . ./
RUN npm run build

EXPOSE 443

FROM nginx

ARG SOURCE
ARG COMMIT_HASH
ARG COMMIT_ID
ARG BUILD_TIME
LABEL source=${SOURCE}
LABEL commit_hash=${COMMIT_HASH}
LABEL commit_id=${COMMIT_ID}
LABEL build_time=${BUILD_TIME}

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user=mosip

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user_group=mosip

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user_uid=1001

# can be passed during Docker build as build time environment for github branch to pickup configuration from.
ARG container_user_gid=1001

# can be passed during Docker build as build time environment for artifactory URL
ARG artifactory_url

# environment variable to pass artifactory url, at docker runtime
ENV artifactory_url_env=${artifactory_url}

ENV nginx_dir=/usr/share/nginx

ENV work_dir=${nginx_dir}/html

ENV i18n_path=${work_dir}/locales

# set working directory for the user
WORKDIR /home/${container_user}

# install packages and create user
RUN apt-get -y update \
    && apt-get install -y wget unzip zip \
    && groupadd -g ${container_user_gid} ${container_user_group} \
    && useradd -u ${container_user_uid} -g ${container_user_group} -s /bin/sh -m ${container_user} \
    && mkdir -p /var/run/nginx /var/tmp/nginx ${work_dir}/locales\
    && chown -R ${container_user}:${container_user} /usr/share/nginx /var/run/nginx /var/tmp/nginx ${work_dir}/locales

ADD configure_start.sh configure_start.sh

RUN chmod +x configure_start.sh

RUN chown ${container_user}:${container_user} configure_start.sh

COPY ./nginx/nginx.conf /etc/nginx/nginx.conf

COPY --from=build /app/build ${work_dir}

RUN echo "ESIGNET_UI_BASE_URL=$ESIGNET_UI_BASE_URL" >> ${work_dir}/env.env && echo "MOCK_RELYING_PARTY_SERVER_URL=$MOCK_RELYING_PARTY_SERVER_URL" >> ${work_dir}/env.env && echo "REDIRECT_URI=$REDIRECT_URI" >> ${work_dir}/env.env && echo "REDIRECT_URI_REGISTRATION=$REDIRECT_URI_REGISTRATION" >> ${work_dir}/env.env && echo "CLIENT_ID=$CLIENT_ID" >> ${work_dir}/env.env && echo "ACRS=$ACRS" >> ${work_dir}/env.env && echo "SIGN_IN_BUTTON_PLUGIN_URL=$SIGN_IN_BUTTON_PLUGIN_URL" >> ${work_dir}/env.env && echo "DISPLAY=$DISPLAY" >> ${work_dir}/env.env && echo "MAX_AGE=$MAX_AGE" >> ${work_dir}/env.env && echo "PROMPT=$PROMPT" >> ${work_dir}/env.env && echo "GRANT_TYPE=$GRANT_TYPE" >> ${work_dir}/env.env && echo "CLAIMS_LOCALES=$CLAIMS_LOCALES" >> ${work_dir}/env.env && echo "SCOPE_USER_PROFILE=$SCOPE_USER_PROFILE" >> ${work_dir}/env.env

# change permissions of file inside working dir
RUN chown -R ${container_user}:${container_user} ${work_dir}

# select container user for all tasks
USER ${container_user_uid}:${container_user_gid}

EXPOSE 9708

ENTRYPOINT [ "./configure_start.sh" ]

# Start Nginx server
CMD echo "starting nginx" ; \
    nginx ; \
    sleep infinity