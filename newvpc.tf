#VPC 
resource "aws_vpc" "main" {
 cidr_block = "10.20.0.0/16"
 tags = {
   Name = "Project VPC"
 }

}

#Igw
resource "aws_internet_gateway" "app-igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "app-igw"
  }
}

#IGW route table 
resource "aws_route_table" "app-igw-rt" {
  vpc_id = aws_vpc.main.id
  depends_on = [aws_vpc_endpoint.glbe,aws_subnet.app_subnet]
  route {
    cidr_block = "10.20.0.0/24"
     vpc_endpoint_id  = aws_vpc_endpoint.glbe.id
  }

  tags = {
    Name = "igw-rt"
  }
}

resource "aws_route_table_association" "app-igw-rt-a" {
  gateway_id     = aws_internet_gateway.app-igw.id
  route_table_id = aws_route_table.app-igw-rt.id
}


#VPC 
resource "aws_vpc" "glbet" {
 cidr_block = "10.10.0.0/16"
 tags = {
   Name = "GLBET VPC"
 }

}

#Igw
resource "aws_internet_gateway" "glbet-igw" {
  vpc_id = aws_vpc.glbet.id

  tags = {
    Name = "glbet-igw"
  }
}

# Create a NAT Gateway Elastic IP
resource "aws_eip" "nat_eip" {
 domain   = "vpc"
 depends_on = [aws_internet_gateway.app-igw]
}
# Create NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.nat_subnet.id

  tags = {
    Name = "project nat"
  }

  depends_on = [aws_internet_gateway.app-igw]
}

#NAT subnet
resource "aws_subnet" "nat_subnet" {
 vpc_id     = aws_vpc.main.id
 availability_zone = data.aws_availability_zones.available.names[0]
 cidr_block = "10.20.2.0/24"
 tags = {
   Name = "NAT-pub-Subnet"
 }
}
#NAT subnet route table
resource "aws_route_table" "nat-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.20.0.0/24"
     vpc_endpoint_id  = aws_vpc_endpoint.glbe.id
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app-igw.id
  }

  tags = {
    Name = "nat-public-rt"
  }
}
# NAT route table assignment
resource "aws_route_table_association" "nat-rt-a" {
  subnet_id     = aws_subnet.nat_subnet.id
  route_table_id = aws_route_table.nat-rt.id
  depends_on = [aws_route_table.nat-rt,aws_subnet.nat_subnet ]
}

#App subnet
resource "aws_subnet" "app_subnet" {
 vpc_id     = aws_vpc.main.id
 availability_zone = data.aws_availability_zones.available.names[0]
 cidr_block = "10.20.0.0/24"
 tags = {
   Name = "App-Subnet"
 }
}
#App subnet route table
resource "aws_route_table" "app-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.20.3.0/24"
    vpc_endpoint_id  = aws_vpc_endpoint.glbe.id
  }

  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id  = aws_vpc_endpoint.glbe.id
  }

  tags = {
    Name = "app-rt"
  }
}

resource "aws_route_table_association" "pub-rt-a" {
  subnet_id      = aws_subnet.app_subnet.id
  route_table_id = aws_route_table.app-rt.id
}


#db subnet
resource "aws_subnet" "db_subnet" {
 vpc_id     = aws_vpc.main.id
 availability_zone = data.aws_availability_zones.available.names[0]
 cidr_block = "10.20.3.0/24"
 tags = {
   Name = "db-Subnet"
 }
}
#db subnet route table
resource "aws_route_table" "db-rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id  = aws_vpc_endpoint.glbe.id
  }
  
  route {
    cidr_block = "10.20.0.0/24"
    vpc_endpoint_id  = aws_vpc_endpoint.glbe.id
  }

  tags = {
    Name = "db-rt"
  }
}

resource "aws_route_table_association" "db-rt-a" {
  subnet_id      = aws_subnet.db_subnet.id
  route_table_id = aws_route_table.db-rt.id
}

#GLBE subnet
resource "aws_subnet" "glbe_subnet" {
 vpc_id     = aws_vpc.main.id
 availability_zone = data.aws_availability_zones.available.names[0]
 cidr_block = "10.20.1.0/24"
 tags = {
   Name = "GLBE-Subnet"
 }
}
#GLBE subnet route table
resource "aws_route_table" "glbe-rt" {
  vpc_id = aws_vpc.main.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id  = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "GLBE-rt"
  }
}

resource "aws_route_table_association" "glbe-rt-a" {
  subnet_id      = aws_subnet.glbe_subnet.id
  route_table_id = aws_route_table.glbe-rt.id
}


#GLBETUN subnet
resource "aws_subnet" "glbet_subnet" {
 vpc_id     = aws_vpc.glbet.id
 availability_zone = data.aws_availability_zones.available.names[0]
 cidr_block = "10.10.0.0/24"
 tags = {
   Name = "GLBET-Subnet"
 }
}
#GLBETUN subnet route table
resource "aws_route_table" "glbet-rt" {
  vpc_id = aws_vpc.glbet.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id  = aws_nat_gateway.fw_nat.id
  }

  tags = {
    Name = "GLBET-rt"
  }
}

resource "aws_route_table_association" "glbet-rt-a" {
  subnet_id      = aws_subnet.glbet_subnet.id
  route_table_id = aws_route_table.glbet-rt.id
}


# Create a NAT Gateway Elastic IP
resource "aws_eip" "fw_nat_eip" {
 domain   = "vpc"
 depends_on = [aws_internet_gateway.glbet-igw]
}
# Create NAT Gateway
resource "aws_nat_gateway" "fw_nat" {
  allocation_id = aws_eip.fw_nat_eip.id
  subnet_id     = aws_subnet.fw_nat_subnet.id

  tags = {
    Name = "fw nat"
  }

  depends_on = [aws_internet_gateway.glbet-igw]
}

#NAT subnet
resource "aws_subnet" "fw_nat_subnet" {
 vpc_id     = aws_vpc.glbet.id
 availability_zone = data.aws_availability_zones.available.names[0]
 cidr_block = "10.10.2.0/24"
 tags = {
   Name = "fw-NAT-pub-Subnet"
 }
}
#NAT subnet route table
resource "aws_route_table" "fw_nat-rt" {
  vpc_id = aws_vpc.glbet.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.glbet-igw.id
  }

  tags = {
    Name = "fw-nat-public-rt"
  }
}
# NAT route table assignment
resource "aws_route_table_association" "fw-nat-rt-a" {
  subnet_id     = aws_subnet.fw_nat_subnet.id
  route_table_id = aws_route_table.fw_nat-rt.id
  depends_on = [aws_route_table.fw_nat-rt,aws_subnet.fw_nat_subnet ]
}