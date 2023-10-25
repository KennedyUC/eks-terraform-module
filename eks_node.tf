resource "aws_iam_role" "EKSNodeGroupRole" {
  name = var.nodes_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  depends_on = [aws_eks_cluster.eks_cluster]
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.EKSNodeGroupRole.name
  depends_on = [aws_iam_role.EKSNodeGroupRole]
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.EKSNodeGroupRole.name
  depends_on = [aws_iam_role.EKSNodeGroupRole]
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.EKSNodeGroupRole.name
  depends_on = [aws_iam_role.EKSNodeGroupRole]
}

resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  version         = var.k8s_version
  node_group_name = "${var.env}-k8s-nodes"
  node_role_arn   = aws_iam_role.EKSNodeGroupRole.arn
  subnet_ids      = aws_subnet.private_subnets[*].id
  instance_types  = [var.instance_type]
  scaling_config {
    desired_size = var.desired_node_count
    min_size     = var.min_node_count
    max_size     = var.max_node_count
  }

  capacity_type  = var.capacity_type
  ami_type       = var.ami_type
  disk_size      = var.node_disk_size

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]

  tags = {
    Name = "${var.project_name}-${var.env}-node"
  }
}
