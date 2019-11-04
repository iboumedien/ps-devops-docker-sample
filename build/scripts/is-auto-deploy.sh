#!/bin/sh
## This script is used as auto deployment feature for Process models (BPM) with WmDeployer based on a repository artificat.
## The following variables need to be set before running the script, otherwise default values will be used instead :
### SAG_HOME       : root directory of Integration Server installation (mandatory)
### INSTANCE_NAME  : Integration Server instance name (mandatory)
### IS_HOST        : Integration server host (default : localhost)
### IS_PORT        : Integration server port (default : 5555)
### IS_USER        : Integration server user (default : Administrator)
### IS_PWD         : Integration server password (default : manage)
### IS_VERSION     : Integration server version (default : 10.5)
### IS_PROJ        : Deployment project name (default : Deployment)
### DIR_DEPLOY     : Scripts directory containing utils scripts (default : $SAG_HOME/IntegrationServer/instances/$INSTANCE_NAME/packages/_deploy)
### DIR_REPOSITORY : Artifact Repository directory containing PM ACDL assets (default : $SAG_HOME/IntegrationServer/instances/$INSTANCE_NAME/packages/$DIR_DEPLOY/$DIR_REPOSITORY)

############# Function check environment variables ##############

check_variables() {

if [ -z "$SAG_HOME" ]; then
    echo "# SAG_HOME environment variable is not defined"
    exit 0
fi

if [ -z "$INSTANCE_NAME" ]; then
    echo "# INSTANCE_NAME environment variable is not defined"
    exit 0
fi

if [ -z "$DIR_DEPLOY" ]; then
    echo "# DIR_DEPLOY environment variable is not defined, auto deployment disbaled"
    exit 0
fi

if [ -z "$DIR_REPOSITORY" ]; then
    echo "# DIR_REPOSITORY environment variable is defined, using default value DIR_DEPLOY/repository"
    DIR_REPOSITORY=$DIR_DEPLOY/repository
fi

if [ -z "$IS_HOST" ]; then
    echo "# IS_HOST environment variable is not defined, using default value localhost"
    IS_HOST="localhost"
fi

if [ -z "$IS_PORT" ]; then
    echo "# IS_PORT environment variable is not defined, using default value 5555"
    IS_PORT="5555"
fi

if [ -z "$IS_USER" ]; then
    echo "# IS_USER environment variable is not defined, using default value Administrator"
    IS_USER="Administrator"

fi

if [ -z "$IS_PWD" ]; then
    echo "# IS_PWD environment variable is not defined, using default value manage"
    IS_PWD="manage"
fi

if [ -z "$IS_VERSION" ]; then
    echo "# IS_VERSION environment variable is not defined, using default value 10.5"
    IS_VERSION="10.5"
fi

if [ -z "$IS_PROJ" ]; then
    echo "# IS_PROJ environment variable is not defined, using default value Deployment"
    IS_PROJ="Deployment"
fi


}

############# Function create project ##############
create_project() {

build_version="$(cat $DIR_DEPLOY/version.txt)"

$SAG_HOME/common/lib/ant/bin/ant -file $DIR_DEPLOY/build-custom.xml createRepositoryProject  \
    -Dsag.install.dir=$SAG_HOME\
    -Dautomator.file=$DIR_DEPLOY/Autmator.xml \
    -Dautomator.template=$DIR_DEPLOY/AutomatorTemplateRepository.xml \
    -Dxslt.template=$DIR_DEPLOY/AutomatorRepositoryBPM.xslt \
    -Ddeployer.home=$SAG_HOME/IntegrationServer/instances/$INSTANCE_NAME/packages/WmDeployer \
    -Ddeployer.host=$IS_HOST \
    -Ddeployer.port=$IS_PORT \
    -Ddeployer.user=$IS_USER \
    -Ddeployer.pwd=$IS_PWD \
    -Drepository.alias="${IS_PROJ}_Repository" \
    -Drepository.path=$DIR_REPOSITORY \
    -Dproj.name=$IS_PROJ\
    -Ddeployment.name="${IS_PROJ}_Dep" \
    -Dmap.name="${IS_PROJ}_Map"  \
    -Dcandidate.name="${IS_PROJ}_Candidate" \
    -Dtarget.alias="IS_LOCAL" \
    -Dtarget.host=$IS_HOST \
    -Dtarget.port=$IS_PORT \
    -Dtarget.user=$IS_USER \
    -Dtarget.pwd=$IS_PWD \
    -Dtarget.version=$IS_VERSION \
    -Dcomposite.name="*" \
    -Dbuild.version=$build_version
 
}

############# Function deploy project ##############
deploy_project() {

$SAG_HOME/common/lib/ant/bin/ant -file $DIR_DEPLOY/build-custom.xml deployProject  \
    -Dsag.install.dir=$SAG_HOME\
    -Ddeployer.home=$SAG_HOME/IntegrationServer/instances/$INSTANCE_NAME/packages/WmDeployer\
    -Ddeployer.host=$IS_HOST \
    -Ddeployer.port=$IS_PORT \
    -Ddeployer.user=$IS_USER \
    -Ddeployer.pwd=$IS_PWD \
    -Dproj.name=$IS_PROJ\
    -Dproj.dc="${IS_PROJ}_Candidate"
}

main() {
	
	base_directory=$(dirname "$0")
	# Set log file 
	log_file="${base_directory}/auto_deploy.log"
	
	if [ ! -f "$log_file" ];
	then
		# Check and set environment variables
		check_variables >> ${log_file}
		# Create Repository project in WmDeployer
		create_project >> ${log_file}
		# Create project deployment checkpoint then deploy
		deploy_project >> ${log_file}
	else
		# Nothing to do...
		echo "File ${log_file} exists, already deployed"
		exit 0
	fi
}

main $*