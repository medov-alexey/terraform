resource "selectel_vpc_project_v2" "my_project" {
  name = "my_project"
}

resource "selectel_iam_serviceuser_v1" "my_serviceuser_1" {
  name         = "my_serviceuser_1"
  password     = random_password.my_serviceuser_1_password.result
  role {
    role_name  = "member"
    scope      = "project"
    project_id = selectel_vpc_project_v2.my_project.id
  }
}
