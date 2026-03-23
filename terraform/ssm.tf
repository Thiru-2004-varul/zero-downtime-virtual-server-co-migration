resource "aws_cloudwatch_log_group" "ssm_sessions" {
  name              = "/aws/ssm/${var.cluster_name}/sessions"
  retention_in_days = 30

  tags = { Name = "${var.cluster_name}-ssm-logs" }
}

resource "aws_iam_role_policy" "eks_node_ssm_logs" {
  name = "ssm-cloudwatch-logs"
  role = aws_iam_role.eks_node_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.ssm_sessions.arn}:*"
    }]
  })
}

resource "aws_ssm_document" "session_preferences" {
  name            = "${var.cluster_name}-SessionManagerPreferences"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "SSM Session Manager preferences for EKS nodes"
    sessionType   = "Standard_Stream"
    inputs = {
      cloudWatchLogGroupName      = aws_cloudwatch_log_group.ssm_sessions.name
      cloudWatchEncryptionEnabled = false
      cloudWatchStreamingEnabled  = true
      s3BucketName                = ""
      s3KeyPrefix                 = ""
      s3EncryptionEnabled         = false
      runAsEnabled                = false
      runAsDefaultUser            = ""
      idleSessionTimeout          = "20"
      maxSessionDuration          = ""
    }
  })

  tags = { Name = "${var.cluster_name}-ssm-prefs" }
}