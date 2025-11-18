# Caravel Secure Logger 

**ChipFoundry BM Labs NVM Power-Up Design Contest Submission**

## Replicating Locally

### Follow these steps to set up your environment and harden the design:

1. **Clone the Repository:**

```bash
git clone https://github.com/Baavanes/caravel_user_neuromorphic_secure.git
```

2. **Prepare Your Environment:**

```bash
cd caravel_user_neuromorphic_secure
make setup
```

3. **Install IPM:**

```bash
pip install cf-ipm
```

4. **Install the Neuromorphic X1 IP:**

```bash
ipm install Neuromorphic_X1_32x32
```

5. **Edit Behavioral Model Name in IP:**

In other words, rename line 16 and line 58...
```
File: ip/Neuromorphic_X1_32x32/hdl/beh_model/Neuromorphic_X1_Beh.v
16: module Neuromorphic_X1_wb (
58: ADDR_MATCH = 32'h3000_0000
```

6. **Run Testbenches:**

```bash
make cocotb-verify-all-rtl
```

7. **Harden the Design:**

```bash
make user_project_wrapper
```

## License

This project is licensed under Apache 2.0 - see LICENSE file for details.
