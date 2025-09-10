#!/bin/bash

# Import existing ECR repositories into Terraform state
# Run this script from the environments/dev directory

echo "Importing existing ECR repositories..."

# Import clan-boards API (clash-of-clans/clan-boards-api)
echo "Importing clash-of-clans/clan-boards-api..."
tofu import module.ecr.aws_ecr_repository.clan_boards_api clash-of-clans/clan-boards-api

# Import message service
echo "Importing clan-boards/message-service..."
tofu import module.ecr.aws_ecr_repository.message_service clan-boards/message-service

# Import user service
echo "Importing clan-boards/user-service..."
tofu import module.ecr.aws_ecr_repository.user_service clan-boards/user-service

# Import notifications service
echo "Importing clan-boards/notifications-service..."
tofu import module.ecr.aws_ecr_repository.notifications_service clan-boards/notifications-service

# Import recruiting service
echo "Importing clan-boards/recruiting..."
tofu import module.ecr.aws_ecr_repository.recruiting clan-boards/recruiting

echo "Import completed. Run 'tofu plan' to verify the state."