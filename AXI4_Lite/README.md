# AXI4-Lite를 이용한 FND 컨트롤러 IP 설계

## 📝 프로젝트 개요

본 프로젝트는 고속 데이터 통신을 위한 **AMBA AXI4-Lite 프로토콜**의 구조를 이해하고, 이를 기반으로 **FND(7-Segment) 컨트롤러 IP(지적 재산)**를 설계하는 것을 목표로 합니다. [cite_start]최종적으로는 SystemVerilog로 설계된 IP를 검증하고, C언어를 통해 FPGA 보드에서 실제 동작을 구현합니다. [cite: 30, 31, 32]

- **주요 목표**:
  1. [cite_start]AXI 버스 구조 설계 및 프로토콜 동작 이해 [cite: 30]
  2. [cite_start]AXI4-Lite 슬레이브로 동작하는 FND 컨트롤러 IP 설계 [cite: 31]
  3. [cite_start]C언어를 이용한 펌웨어 작성 및 시스템 기능 구현 [cite: 32]

---

## 🛠️ 개발 환경

- [cite_start]**언어**: SystemVerilog, C [cite: 46]
- [cite_start]**개발 툴**: Vivado 2020.2, Vitis [cite: 38, 42]
- [cite_start]**FPGA**: Xilinx Basys3 [cite: 40]

---

## 📖 핵심 기술: AXI4-Lite

[cite_start]**AXI(Advanced eXtensible Interface)**는 ARM사에서 정의한 AMBA 인터페이스 중 하나로, 고속 데이터 전송을 위해 설계된 버스 프로토콜입니다. [cite: 63, 64] 본 프로젝트에서는 경량화 버전인 **AXI4-Lite**를 사용합니다.

### AXI4-Lite의 주요 특징

- [cite_start]**5개의 독립 채널**: 주소와 데이터 경로가 분리되어 읽기와 쓰기 동작이 병렬로 처리될 수 있어 효율이 극대화됩니다. [cite: 80, 87, 88]
  - [cite_start]쓰기 채널: Write Address (AW), Write Data (W), Write Response (B) [cite: 82, 83, 84]
  - [cite_start]읽기 채널: Read Address (AR), Read Data (R) [cite: 85, 86]
- [cite_start]**핸드셰이크 메커니즘**: `VALID`와 `READY` 신호를 이용한 핸드셰이킹을 통해 데이터 전송의 안정성을 보장합니다. [cite: 90, 128]

---

## ⚙️ 설계 구조: FND 컨트롤러 IP

AXI4-Lite 버스의 슬레이브로 동작하는 FND(7-Segment) 컨트롤러를 설계했습니다. 마스터(CPU)는 AXI4-Lite 프로토콜을 통해 FND 컨트롤러의 레지스터에 값을 쓰거나 읽을 수 있습니다.

### 레지스터 맵 (Register Map)

- **Control Register (주소 `0x00`)**: FND의 동작을 제어 (e.g., Enable/Disable)
- **Data Register (주소 `0x04`)**: FND에 표시할 숫자 또는 문자 데이터

---

## 🔬 검증 (Verification)

SystemVerilog 테스트벤치를 구축하여 AXI4-Lite 프로토콜의 쓰기/읽기 트랜잭션이 정상적으로 동작하는지, 그리고 레지스터에 기록된 값에 따라 FND가 올바르게 제어되는지를 시뮬레이션 파형을 통해 검증했습니다.

- **주요 검증 항목**:
  - AXI 쓰기 트랜잭션을 통한 레지스터 값 변경 확인
  - AXI 읽기 트랜잭션을 통한 레지스터 값 조회 확인
  - 레지스터 값에 따른 FND 출력 신호 변화 검증

---

## 🔧 문제 해결 (Troubleshooting)

- **문제**: Vitis 환경에서 C언어 코드 빌드 시 `printf` 함수를 포함하는 표준 입출력 헤더(`stdio.h`)를 인식하지 못하는 오류 발생
- [cite_start]**해결**: 프로젝트의 **Makefile** 설정을 수정하여 표준 라이브러리가 올바르게 링크되도록 조치하여 문제를 해결하고, UART를 통한 `printf` 출력을 최종적으로 확인했습니다. [cite: 7]

---

## 🤔 고찰

이번 프로젝트를 통해 고속 버스 인터페이스인 AXI의 동작 원리를 깊이 있게 학습할 수 있었습니다. 특히 5개의 독립 채널 구조와 핸드셰이킹 메커니즘을 이해하는 과정이 중요했습니다. APB와 같은 단순한 프로토콜과 달리, 채널 간의 타이밍을 고려하는 과정은 복잡했지만, 표준화된 IP 설계 방식을 통해 다양한 모듈을 일관성 있게 통합할 수 있다는 장점을 체감했습니다. [cite_start]이 경험을 바탕으로 향후에는 AXI의 파이프라이닝 특성을 활용한 더 복잡하고 성능이 높은 시스템을 설계해보고 싶습니다. [cite: 8]