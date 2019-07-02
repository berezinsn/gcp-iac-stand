terraform               {
  required_version      = "0.11.14"
  backend "gcs"         {
    bucket              = "terraform64"
    prefix              = "terraform/state"
  }
}

provider "google"       {
  version               = "1.19.1"
  credentials           = "${file("../auth/account.json")}"
  project               = "${var.GP}"
  region                = "${var.REG}"
}

resource "google_compute_health_check" "l3_autohealing_health_check" {
  name                  = "l3-autohealing-health-check"
  timeout_sec           = 5
  check_interval_sec    = 20
  healthy_threshold     = 1
  unhealthy_threshold   = 5
  tcp_health_check      {
    port = "80"
  }
}

resource "google_compute_http_health_check" "l7_balancing_health_check" {
  name                  = "l7-balancing-health-check"
  request_path          = "/health"
  timeout_sec           = 10
  check_interval_sec    = 20
  healthy_threshold     = 1
  unhealthy_threshold   = 5
}

resource "google_compute_firewall" "firewall" {
  name                  = "allow-health-check"
  network               = "default"
  target_tags           = ["apache"]
  allow                 {
    protocol            = "tcp"
    ports               = ["80"]
  }
}

resource "google_compute_target_pool" "load_balancer" {
  name                  = "lb"
  health_checks         = ["${google_compute_http_health_check.l7_balancing_health_check.self_link}"]
}

resource "google_compute_instance_template" "apache" {
  name                  = "apache-cluster-template"
  machine_type          = "f1-micro"
  tags                  = ["apache"]
  network_interface     {
    network             = "default"
    access_config       {
    }
  }
  disk                  {
    source_image        = "${var.IMG}"
  }
}

resource "google_compute_instance_group_manager" "instance_group_manager" {
  name                  = "instance-group-manager"
  target_pools          = ["${google_compute_target_pool.load_balancer.self_link}"]
  instance_template     = "${google_compute_instance_template.apache.self_link}"
  base_instance_name    = "apache"
  zone                  = "europe-west1-b"
  target_size           = 3
  auto_healing_policies {
    health_check        = "${google_compute_health_check.l3_autohealing_health_check.self_link}"
    initial_delay_sec   = 300
  }
}

resource "google_compute_autoscaler" "autoscaler" {
  name                  = "autoscaler"
  zone                  = "europe-west1-b"
  target                = "${google_compute_instance_group_manager.instance_group_manager.self_link}"
  autoscaling_policy    {
    max_replicas        = 3
    min_replicas        = 3
    cooldown_period     = 60
  }
}

resource "google_compute_forwarding_rule" "load_balancer_rule" {
  name                  = "${var.LB}"
  target                = "${google_compute_target_pool.load_balancer.self_link}"
  port_range            = "80"
  network_tier          = "STANDARD"
}