# Recovery-Compiler 🤖

This GitHub Action Let's You Compile Recovery For Android Devices.

## Features 📜

- Let's you Compile Without Any Hassle Of Setting Up Environment.
- Just Setup Env Variables & Everything Is Automated.

### Build Platform

Build either on `ubuntu-18.04` or `ubuntu-20.04` also Known As `ubuntu-latest` runner environment.

### Preparation

You MUST use `rokibhasansagar/slimhub_actions@main` Action before running this Compiler Action to Cleanup Spaces.

### Output

As the Working Directory where the repo-sync will occur is set in `/home/runner/builder/`, accessible from `${BuildPath}`.

So, Compiled Recovery will be found under `/home/runner/builder/out/target/product/*/*{.img,.zip}`. Same can be accessed using `${BuildPath}/out/target/product/${CODENAME}/*{.img,.zip}`

## Detailed Usage 👨‍💻

**Note:** If you want to minimize the input in the Workflow YAML File, Read On.

- Rename your Device Tree Repo in this format, `android_device_VENDOR_CODENAME`.
  If you do this, you won't need to add `VENDOR`, `CODENAME` and `DT_LINK` in the yaml `env` key.
  They will be fetched automatically from your Repo address.
- `KERNEL_LINK` is optional, use this only if you want to build kernel from source code.
- `TARGET` is set as `recoveryimage` by default.
  Unless you want to build `bootimage` or something, don't provide anything.
- `FLAVOR` is set as `eng` by default.
  Unless you want to build an `userdebug` build, don't provide anything.
- `EXTRA_CMD` key is added if you want to run some user-defined commands such as patchworks before compilation.
  Don't use it if you don't have anything to add.
- `TZ` (Timezone) is set as `UTC` by default.
  Unless you want to change the Timezone, ignore it.

**Congratulations**, If you followed these steps, you will need to provide only one `env` variable, `MANIFEST`. That's it.

If you still want to do things old-fashioned way, here is the full format -

```yaml
# ...
jobs:
  recovery_builder:
    runs-on: ubuntu-latest
    # You can use either of the ubuntu-18.04 or ubuntu-20.04 runner
    steps:
      # Checking out the repo is not mandatory, so don't
      #- uses: actions/checkout@v2
      # Cleanup The Actions Workspace Using Custom Composite Run Actions
      - name: "Cleanup Environment"
        uses: rokibhasansagar/slimhub_actions@main
      # That's it! Now use this action
      - name: "Recovery Compilation"
        uses: CarbonatedBlack/Recovery-Compiler@production
        env:
          MANIFEST: "Recovery Manifest URL with -b branch"     # or "orangefox10" for Orangefox Android v10
          DT_LINK: "Your Device Tree Link"
          VENDOR: "Your Device's Vendor name as in used inside DT."  # Example: xiaomi, samsung, asus, etc.
          CODENAME: "Your Device's Codename as in used inside DT."   # Example: nikel, phoenix, ginkgo, etc.
          KERNEL_LINK: "Kernel repo link with optional -b branch."   # Only for building kernel from source. Ignore if using prebuilt.
          TARGET: "Set as recoveryimage (or bootimage if no recovery partition avaiable)"
          FLAVOR: "eng or userdebug"
          EXTRA_CMD: "If you want to Execute any external Command Before Compilation Starts"
          TZ: "Asia/Kolkata"           # Set Time-Zone According To Your Region
```

## Credits 🥰

[rokibhasansagar](https://github.com/rokibhasansagar) For His Cleanup Scripts And Great Help

## License 🔖

Licensed Under [GPLV3](https://github.com/Carbonatedblack/Recovery-Compiler/blob/production/LICENSE)

