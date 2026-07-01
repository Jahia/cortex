---
name: jahia-java-module-dev-loop
description: >-
  Build, deploy, and test a Jahia Java module project on a local running Jahia — the
  inner dev loop. Discovers the repo's Jahia module(s) and any optional Cypress test
  module, builds each with the JDK its POM targets, deploys via the provisioning API,
  verifies the deployment in the Jahia logs, and runs the Cypress e2e suite. Use to set
  up local development on a Jahia Java-module repository, or to rebuild / redeploy /
  re-run the tests after a change. (Jahia JavaScript modules have a different dev loop
  and are out of scope here.)
---

# Jahia Java module — local dev loop

Get a Jahia Java module project built, deployed to a **running** Jahia, and its tests
green — locally. Works for a single module or a mono-repo with several modules plus an
optional Cypress test module.

> Jahia also supports **JavaScript modules**, which have a different build/deploy loop;
> this skill covers **Java (Maven / OSGi)** modules only.

**Prerequisites**

- A running Jahia 8.x — **local Docker is recommended** (you'll tail its logs to verify
  each deployment, Step 5). Local-dev defaults assumed below: `http://localhost:8080`,
  user `root`, password `root1234`.
- Maven, and one or more JDKs (the version depends on the module — see Step 2).
- Node + yarn, if the repo has a Cypress suite (`tests/`).

## Step 1 — Discover what to build and deploy

Identify the **Jahia module(s)** in the repo. A Maven project is a Jahia (Java) module
when it either:

- declares the Jahia module parent — `org.jahia.modules:jahia-modules`
  (`<parent><artifactId>jahia-modules</artifactId>…</parent>`), or
- sets the Jahia OSGi manifest headers that mark the bundle as a Jahia module (chiefly
  `Jahia-Module-Type`) in its `maven-bundle-plugin` configuration.

Such modules build as `<packaging>bundle</packaging>` OSGi bundles. A repo may have one,
or several in a mono-repo.

Also look for an **optional test module** — a Jahia module (of *any* `Jahia-Module-Type`)
used only by the tests, often under `tests/` (e.g. `tests/jahia-module`). It ships
whatever the specs depend on (node types, templates, sample content or config, …), so
**it must be built and deployed too, or the e2e suite fails**.

Build the ordered list = every product module + the test module (if present); build and
deploy each with the same sequence (Steps 2–5).

## Step 2 — Determine the JDK (per module)

Jahia 8 modules compile to **Java 11 or Java 17**. Read the target from the module's
`pom.xml` rather than assuming — in a mono-repo modules may differ:

- `<maven.compiler.release>` → `11` or `17` (Jahia **8.2.0+** may target 17). If absent,
  check `maven.compiler.source` / `maven.compiler.target` or the parent POM; assume
  **11** if nothing is specified.
- **Caveat — Jahia 8.1.x:** modules **cannot** compile with Java 17. And if the module
  uses **Spring** (rather than OSGi Blueprint), it must be compiled with **JDK 8** —
  otherwise it compiles but **silently fails to deploy** on Jahia.

Set `JAVA_HOME` to the matching JDK before building. On macOS:
`export JAVA_HOME=$(/usr/libexec/java_home -v <version>)` (list installed JDKs with
`/usr/libexec/java_home -V`).

## Step 3 — Build each module

From the module's directory:

```bash
mvn clean install                 # full build (runs the module's Java tests)
mvn clean install -DskipTests     # package only -> target/<artifact>-<version>.jar
```

## Step 4 — Deploy each module to the running Jahia (provisioning API)

Push the locally-built jar over HTTP to the running instance. The jar is uploaded as a
multipart part and referenced by its **bare filename** (a `file:` / `mvn:` URL would be
fetched from a repository instead):

```bash
JAR=target/<artifact>-<version>.jar
printf -- '- installModule: "%s"\n  autoStart: true\n  uninstallPreviousVersion: true\n' "$(basename "$JAR")" > /tmp/apm-provision.yaml
curl -s -u root:root1234 \
  -F 'script=@/tmp/apm-provision.yaml;type=application/yaml' \
  -F "file=@$JAR" \
  http://localhost:8080/modules/api/provisioning
```

A successful HTTP response shows `install` / `start` with `"Operation successful"`.
Deploy the test module the same way (point `JAR=` at its jar). Adjust `-u user:password`
and the base URL to your instance. Then verify it actually started (Step 5).

## Step 5 — Verify the deployment in the Jahia logs

An `"Operation successful"` response means the bundle was *accepted*, not that it
*started cleanly* — always confirm in the Jahia logs. With local Docker:

```bash
docker logs -f <jahia-container>      # e.g. docker logs -f jahia
```

A healthy install shows the bundle deploying and starting, with **no** stack traces —
e.g. `Deploying content for DX OSGi bundle <module> vX … Done deploying`, `Finished
starting DX OSGi bundle <module> vX in <ms>`, followed by the module's own activation
logs (DS components activated, services registered).

Watch for failure signs and fix before moving on:

- `ERROR` / exceptions during activation (e.g. a component `@Activate` throwing), or the
  bundle left in `Installed` / `Resolved` instead of `Active`;
- database / schema errors on first start;
- `Unresolved requirement` / missing-package errors (an `Import-Package` the runtime
  doesn't provide).

## Step 6 — Run the Cypress e2e suite (if the repo has `tests/`)

Jahia repos put Cypress tests under `tests/` (specs in `tests/cypress/e2e`, helpers from
`@jahia/cypress`). The product module(s) **and** the test module must be deployed and
verified (Steps 4–5) first.

```bash
cd tests
yarn install     # first time only
yarn e2e:ci      # headless    (cypress run)
yarn e2e:debug   # interactive (cypress open)
```

**Non-default instance.** The `@jahia/cypress` plugin uses the defaults
(`http://localhost:8080` + `root1234`) **only when no environment variables are set**.
To target another host or credentials, export **all three together** — a partial
override leaves the rest undefined and authentication breaks:

```bash
export JAHIA_URL=http://my-host:8080
export JAHIA_PROCESSING_URL=$JAHIA_URL   # same as JAHIA_URL for a single-node instance
export SUPER_USER_PASSWORD=my-root-password
```

`JAHIA_URL` becomes the Cypress `baseUrl`. If a spec creates sites with a fixed
`serverName` (often `'localhost'`) and your instance enforces a different server name /
virtual host, change it in the spec.
