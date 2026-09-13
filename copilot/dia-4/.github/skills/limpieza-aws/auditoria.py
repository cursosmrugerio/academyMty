# Auditoría de limpieza de la Semana 5 · solo lectura.
# Se pasa TAL CUAL como `code` a la herramienta aws___run_script del servidor MCP de AWS.
# Corre en el sandbox de AWS: `call_boto3` y `asyncio` ya vienen importados ahí.
# Solo usa operaciones Describe*/List* de metadatos que la política ViewOnlyAccess permite (medido el
# 12-sep-2026). Las conexiones de CodePipeline (codeconnections:ListConnections) NO entran en
# ViewOnlyAccess y no cuestan: se revisan a mano en la consola (ver SKILL.md).

REGIONES = ["us-east-1", "us-east-2"]


async def leer(servicio, operacion, region=None, params=None):
    """Una lectura que nunca revienta: devuelve la respuesta o {"error": texto ya explicado}."""
    try:
        return await call_boto3(service_name=servicio, operation_name=operacion,
                                region_name=region, params=params or {})
    except Exception as e:
        texto = str(e)
        if "NoSuchEntity" in texto:
            return {}  # el recurso que se buscaba no existe: no hay nada que borrar
        if "service control policy" in texto:
            # Cuentas de la experiencia nueva: solo tienen habilitada su región (medido el 12-sep).
            return {"error": "NO SE PUEDE LEER: la cuenta bloquea esta región (SCP). Si nunca la usaste, es normal."}
        return {"error": "NO SE PUEDE LEER: " + texto[:250]}


def err(r):
    return r.get("error") if isinstance(r, dict) else "NO SE PUEDE LEER: " + str(r)[:250]


async def por_region(region):
    (ec2, eips, vols, llaves, sgs, rds, ddb, pipes, builds, deploys) = await asyncio.gather(
        leer("ec2", "DescribeInstances", region),
        leer("ec2", "DescribeAddresses", region),
        leer("ec2", "DescribeVolumes", region),
        leer("ec2", "DescribeKeyPairs", region),
        leer("ec2", "DescribeSecurityGroups", region),
        leer("rds", "DescribeDBInstances", region),
        leer("dynamodb", "ListTables", region),
        leer("codepipeline", "ListPipelines", region),
        leer("codebuild", "ListProjects", region),
        leer("codedeploy", "ListApplications", region),
    )
    r = {}
    r["EC2 instancias"] = err(ec2) or [
        f'{i["InstanceId"]} ({i["State"]["Name"]}) {next((t["Value"] for t in i.get("Tags", []) if t["Key"] == "Name"), "")}'
        for res in ec2.get("Reservations", []) for i in res["Instances"]
        if i["State"]["Name"] != "terminated"]
    r["EC2 Elastic IPs"] = err(eips) or [a.get("PublicIp") for a in eips.get("Addresses", [])]
    r["EC2 volúmenes EBS"] = err(vols) or [f'{v["VolumeId"]} ({v["State"]}, {v["Size"]} GB)' for v in vols.get("Volumes", [])]
    r["EC2 key pairs"] = err(llaves) or [k["KeyName"] for k in llaves.get("KeyPairs", [])]
    r["EC2 security groups (sin default)"] = err(sgs) or [
        f'{g["GroupName"]} ({g["GroupId"]})' for g in sgs.get("SecurityGroups", []) if g["GroupName"] != "default"]
    r["RDS instancias"] = err(rds) or [f'{d["DBInstanceIdentifier"]} ({d["DBInstanceStatus"]})' for d in rds.get("DBInstances", [])]
    r["DynamoDB tablas"] = err(ddb) or ddb.get("TableNames", [])
    r["CodePipeline pipelines"] = err(pipes) or [p["name"] for p in pipes.get("pipelines", [])]
    r["CodeBuild proyectos"] = err(builds) or builds.get("projects", [])
    r["CodeDeploy aplicaciones"] = err(deploys) or deploys.get("applications", [])
    return region, r


async def globales():
    (buckets, roles, cf, llaves_admin) = await asyncio.gather(
        leer("s3", "ListBuckets", "us-east-1"),
        leer("iam", "ListRoles", "us-east-1"),
        leer("cloudfront", "ListDistributions", "us-east-1"),
        leer("iam", "ListAccessKeys", "us-east-1", {"UserName": "taskflow-admin"}),
    )
    g = {}
    g["S3 buckets"] = err(buckets) or [b["Name"] for b in buckets.get("Buckets", [])]
    # Solo los roles que crea el curso (los de AWS empiezan por AWSServiceRole/aws-*).
    g["IAM roles del curso"] = err(roles) or [
        x["RoleName"] for x in roles.get("Roles", [])
        if any(p in x["RoleName"].lower() for p in ("taskflow", "codebuild", "codepipeline", "codedeploy"))]
    g["CloudFront distribuciones"] = err(cf) or [
        d["Id"] for d in cf.get("DistributionList", {}).get("Items", [])]
    g["Access keys de taskflow-admin"] = err(llaves_admin) or [
        f'{k["AccessKeyId"][:8]}… ({k["Status"]})' for k in llaves_admin.get("AccessKeyMetadata", [])]
    return g


resultados = await asyncio.gather(*[por_region(r) for r in REGIONES], globales())
result = {"regiones": dict(resultados[:-1]), "globales": resultados[-1]}
result
