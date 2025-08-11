[options]
addons_path = ${ODOO_ADDONS_DIR}
data_dir = ${ODOO_DATA_DIR}

admin_passwd = ${ODOO_PASSWORD}
email_from = ${ODOO_EMAIL}

; csv_internal_sep = ,

db_host = ${ODOO_DATABASE_HOST}
db_port = ${ODOO_DATABASE_PORT_NUMBER}
db_name = ${ODOO_DATABASE_NAME}
db_user = ${ODOO_DATABASE_USER}
db_password = ${ODOO_DATABASE_PASSWORD}
db_maxconn = ${ODOO_DATABASE_MAXCONN}
db_sslmode = ${ODOO_DATABASE_SSLMODE}
db_template = ${ODOO_DATABASE_TEMPLATE}
dbfilter = ${ODOO_DATABASE_FILTER_OVERRIDE}

; debug_mode = False

; limit_memory_hard = 2684354560
; limit_memory_soft = 2147483648
; limit_request = 8192
; limit_time_cpu = 60
; limit_time_real = 120

; list_db = True

; log_db = False
; log_handler = [':INFO']
; log_level = info
; logfile = None
; longpolling_port = 8072
; max_cron_threads = 2
; osv_memory_age_limit = 1.0
; osv_memory_count_limit = False
; smtp_password = False
; smtp_port = 25
; smtp_server = localhost
; smtp_ssl = False
; smtp_user = False
; workers = 0
; xmlrpc = True
; xmlrpc_interface = 
; xmlrpc_port = 8069
; xmlrpcs = True
; xmlrpcs_interface = 
; xmlrpcs_port = 8071

[options]
addons_path = /opt/bitnami/odoo/addons,/opt/bitnami/odoo/extraaddons/oca,/opt/bitnami/odoo/extraaddons/openg2p-registry,/opt/bitnami/odoo/extraaddons/openg2p-social-registry
data_dir = /bitnami/odoo/data
admin_passwd = W1wLiZtI8B
; csv_internal_sep = ,

debug_mode = False
http_port = 8069
; limit_memory_hard = 2684354560
; limit_memory_soft = 2147483648
; limit_request = 8192
; https://www.odoo.com/forum/help-1/question/cpu-time-limit-exceeded-how-to-solve-it-87922
limit_time_cpu = 90
limit_time_real = 5000
list_db = False
log_db = False
log_handler = [":INFO"]
; log_level = info
; logfile = /opt/bitnami/odoo/log/odoo-server.log
longpolling_port = 8072
; https://www.odoo.com/es_ES/forum/ayuda-1/could-not-obtain-lock-on-row-in-relation-ir-cron-74519
max_cron_threads = 1
pidfile = /opt/bitnami/odoo/tmp/odoo.pid
; Odoo will always be running behind a proxy (e.g. Docker or Apache)
proxy_mode = True
; osv_memory_age_limit = 1.0
; osv_memory_count_limit = False
; pg_path =
; smtp_password = False
smtp_port = 25
smtp_server = socialregistry-mail
; smtp_ssl = False
; smtp_user = False
; without_demo = False
; workers = 0
server_wide_modules = web,queue_job