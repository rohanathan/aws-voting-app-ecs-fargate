variable "project"          { type = string }
variable "env"              { type = string }
variable "region"           { type = string }
variable "name"             { type = string }
variable "image"            { type = string }
variable "container_port"   { 
    type = number 
    default = 8080 
    }
variable "cpu"              { 
    type = string 
    default = "256" 
    }
variable "memory"           { 
    type = string 
    default = "512" 
    }
variable "environment"      {
     type = map(string) 
     default = {} 
     }
variable "vpc_id"           { type = string }
variable "subnet_ids"       { type = list(string) }
variable "assign_public_ip" { 
    type = bool 
    default = false 
    }
variable "execution_role_arn" { type = string }
variable "task_role_arn"      { type = string }
variable "log_group"          { type = string }
variable "listener_arn"       { type = string }
variable "alb_sg_id"          { type = string }
variable "health_check_path"  { 
    type = string 
    default = "/health" 
    }
variable "path_patterns"      { type = list(string) }
variable "priority"           { type = number }
variable "desired_count"      { 
    type = number 
    default = 2 
    }

# New inputs for shared cluster and toggles
variable "cluster_arn"        { type = string }
variable "cluster_name"       { type = string }
variable "attach_to_alb"      {
     type = bool   
     default = true 
     }

# Optional autoscaling
variable "enable_autoscaling" {
     type = bool   
     default = false 
     }
variable "min_count"          { 
    type = number 
    default = 1 
    }
variable "max_count"          { 
    type = number 
    default = 3 
    }
variable "cpu_target"         { 
    type = number 
    default = 50 
    }
