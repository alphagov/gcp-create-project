#!/bin/bash
# to do: installation script so runs nativley from terminal, eg alias?

set_project_id () {
    read -p "Please enter your new Google Cloud Project ID: " project_id
}

set_programme () {
    read -p "Please enter your programme: " programme
}

set_team () {
    read -p "Please enter your team (use hyphens instead of spaces): " team
}

list_orgs (){
    echo "These are the organisations you have access to: "
    gcloud organizations list
    echo ""
    read -p "Please enter your organization ID: " org_id
    echo ""
}

exit_setup () {
  exit "Exiting GCP project creator. Setup failed."
}

set_project_id
set_programme
set_team

echo "These are the organisations you have access to: "
gcloud organizations list
echo ""
read -p "Please enter your organization ID: " org_id
echo ""

echo $"These are the folders you have access to: "
# Enumerates Folders recursively
FORMAT="csv[no-heading](name,displayName.encode(base64))"
folders()
{
  LINES=("$@")
  for LINE in ${LINES[@]}
  do
    # Parses lines of the form folder,name
    VALUES=(${LINE//,/ })
    FOLDER=${VALUES[0]}
    # Decodes the encoded name
    NAME=$(echo ${VALUES[1]} | base64 --decode)
    echo "Folder: ${FOLDER} (${NAME})"
    folders $(gcloud resource-manager folders list \
      --folder=${FOLDER} \
      --format="${FORMAT}")
  done
}

# Start at the Org
echo "Org: ${org_id}"
LINES=$(gcloud resource-manager folders list \
  --organization=${org_id} \
  --format="${FORMAT}")

# Descend
folders ${LINES[0]}

read -p "Which folder would you like to create your project under: " folder_id

create_project (){
    gcloud projects create $project_id --name=$project_id --folder=$folder_id --labels=programme=$programme --labels=team=$team
}


if create_project; then
    cd ..
	echo "Project created."
else
    cd ..
    read -p  "Function creation failed. Try again with a new name? y/n: " exit_response
    if [ $exit_response = "n" ]; then
        exit_setup
    else
        set_project_id
        create_project
    fi
fi