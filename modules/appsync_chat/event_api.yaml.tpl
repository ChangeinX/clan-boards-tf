Resources:
  ChatEventApi:
    Type: AWS::AppSync::EventApi
    Properties:
      Name: ${api_name}
      AuthenticationType: OPENID_CONNECT
      OpenIDConnectConfig:
        Issuer: https://accounts.google.com
        ClientId: ${client_id}
        AuthTTL: 3600
        IatTTL: 3600
      AdditionalAuthenticationProviders:
        - AuthenticationType: AWS_IAM
  ChatHistoryDatasource:
    Type: AWS::AppSync::DataSource
    Properties:
      ApiId: !Ref ChatEventApi
      Name: ChatHistory
      Type: AMAZON_DYNAMODB
      ServiceRoleArn: ${service_role}
      DynamoDBConfig:
        TableName: ${table_name}
        AwsRegion: ${region}
  GroupsNamespace:
    Type: AWS::AppSync::Channel
    Properties:
      ApiId: !Ref ChatEventApi
      Name: /groups/{groupId}
      DataSourceName: ChatHistory
  GlobalNamespace:
    Type: AWS::AppSync::Channel
    Properties:
      ApiId: !Ref ChatEventApi
      Name: /global
      DataSourceName: ChatHistory
Outputs:
  ApiId:
    Value: !Ref ChatEventApi
  ApiArn:
    Value: !GetAtt ChatEventApi.Arn
  RealTimeUrl:
    Value: !GetAtt ChatEventApi.RealTimeUrl
  GraphQLUrl:
    Value: !GetAtt ChatEventApi.GraphQLUrl
