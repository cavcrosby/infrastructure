# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursive variables
SHELL = /usr/bin/sh
PROJECT_CONFIG_FILE_NAME = .conf

# executables
ENVSUBST = envsubst

# targets
ALL = all
SCRIPTS = scripts
CONFIGS = configs
HELP = help
CLEAN = clean

# should list all the vars in the multiline var below
JENKINS_MAIN_NODE_URL = $${JENKINS_MAIN_NODE_URL}
JENKINS_AGENT_NAME = $${JENKINS_AGENT_NAME}
JENKINS_USERNAME = $${JENKINS_USERNAME}
JENKINS_PASSWORD = $${JENKINS_PASSWORD}
JENKINS_WORKINGDIR = $${JENKINS_WORKINGDIR}
project_config_file_vars = \
	${JENKINS_MAIN_NODE_URL}\
	${JENKINS_AGENT_NAME}\
	${JENKINS_USERNAME}\
	${JENKINS_PASSWORD}\
	${JENKINS_WORKINGDIR}

define PROJECT_CONFIG_FILE =
cat << _EOF_
#
#
# Config file to centralize vars, and to aggregate common vars.

# common vars
export JENKINS_MAIN_NODE_URL=

# needed to construct agentopts
export JENKINS_AGENT_NAME=
export JENKINS_USERNAME=
export JENKINS_PASSWORD=
export JENKINS_WORKINGDIR=
_EOF_
endef
# Use the $(value ...) function if there are other variables in the multi-line
# variable that should be evaluated by the shell and not make! e.g. 
# export PROJECT_CONFIG_FILE = $(value _PROJECT_CONFIG_FILE)
export PROJECT_CONFIG_FILE

# simply expanded variables
project_configs_dir_path := ./configs
project_scripts_dir_path := ./scripts
CONFIG_EXT := .cfg
config_wildcard := %${CONFIG_EXT}
SHELL_TEMPLATE_EXT := .shtpl
shell_template_wildcard := %${SHELL_TEMPLATE_EXT}
config_shell_template_ext := ${CONFIG_EXT}${SHELL_TEMPLATE_EXT}
config_shell_template_wildcard := %${CONFIG_EXT}${SHELL_TEMPLATE_EXT}
config_shell_templates := $(shell find ${project_configs_dir_path} -name *${config_shell_template_ext})
script_shell_templates := $(shell find ${project_scripts_dir_path} -name *${SHELL_TEMPLATE_EXT})

# Determines the config/script name(s) to be generated from the template(s).
# Short hand notation for string substitution: $(text:pattern=replacement).
_configs := $(config_shell_templates:${config_shell_template_wildcard}=${config_wildcard})
_scripts := $(script_shell_templates:${SHELL_TEMPLATE_EXT}=)

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Available make targets:'
>	@echo '  ${ALL}              - generates all targets except ${PROJECT_CONFIG_FILE_NAME}'
>	@echo '  ${PROJECT_CONFIG_FILE_NAME}            - generates the configuration file to be used by other'
>	@echo '                     make targets. Particularly targets formed from shell'
>	@echo '                     templates'
>	@echo '  ${CONFIGS}          - generates the configuration files to be used by the'
>	@echo '                     entire project, depends on ${PROJECT_CONFIG_FILE_NAME} being filled in'
>	@echo '  ${SCRIPTS}          - generates the scripts to be used from their templates'
>	@echo '                     also depends on ${PROJECT_CONFIG_FILE_NAME} being filled in'
>	@echo '  ${CLEAN}            - removes files generated from other targets except ${PROJECT_CONFIG_FILE_NAME}'

${PROJECT_CONFIG_FILE_NAME}:
>	eval "$${PROJECT_CONFIG_FILE}" > "./${PROJECT_CONFIG_FILE_NAME}"

.PHONY: ${ALL}
${ALL}: ${CONFIGS} ${SCRIPTS}

.PHONY: ${CONFIGS}
${CONFIGS}: ${_configs}

.PHONY: ${SCRIPTS}
${SCRIPTS}: ${_scripts}

# custom implicit rules for the above targets
${project_configs_dir_path}/${config_wildcard}: ${project_configs_dir_path}/${config_shell_template_wildcard}
>	@[ -f "./${PROJECT_CONFIG_FILE_NAME}" ] || { echo "make: ${PROJECT_CONFIG_FILE_NAME} must be generated, run 'make ${PROJECT_CONFIG_FILE_NAME}'"; exit 1; }
>	. "./${PROJECT_CONFIG_FILE_NAME}" && ${ENVSUBST} '${project_config_file_vars}' < "$<" > "$@"

# All scripts at the moment are assumed to have no extension hence no wildcard var
# on the target.
${project_scripts_dir_path}/%: ${project_scripts_dir_path}/${shell_template_wildcard}
>	@[ -f "./${PROJECT_CONFIG_FILE_NAME}" ] || { echo "make: ${PROJECT_CONFIG_FILE_NAME} must be generated, run 'make ${PROJECT_CONFIG_FILE_NAME}'"; exit 1; }
>	. "./${PROJECT_CONFIG_FILE_NAME}" && ${ENVSUBST} '${project_config_file_vars}' < "$<" > "$@"

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force ${project_configs_dir_path}/*${CONFIG_EXT}
>	rm --force ${_scripts}
