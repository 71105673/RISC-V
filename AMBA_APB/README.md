# AMBA APB를 이용한 RISC-V 주변장치 설계 프로젝트

## 📝 프로젝트 개요

본 프로젝트는 **RISC-V Multi-Cycle CPU**와 저전력/저속 통신을 위한 **AMBA APB (Advanced Peripheral Bus) 프로토콜**을 활용하여 주변장치(Peripheral)를 설계하고 검증하는 것을 목표로 합니다.

- **주요 목표**:
  1. RISC-V CPU와 연동되는 AMBA APB 기반 주변장치 설계
  2. 클래스 기반의 SystemVerilog 테스트벤치(UVM 등)를 이용한 DUT(설계 모듈) 검증
  3. C언어를 활용한 최종 시스템 기능 구현 및 FPGA 보드 레벨 검증

---

## 🛠️ 개발 환경

- **언어**: SystemVerilog, C
- **개발 툴**: Vivado 2020.2
- **FPGA**: Xilinx Basys3

---

## 📖 핵심 기술: AMBA APB

**AMBA APB**는 ARM사에서 정의한 버스 프로토콜로, 저속의 주변장치와의 통신을 담당합니다. 단순한 2단계(Setup-Access) 구조로 구현이 용이하고 저전력 소비에 최적화되어 있어 임베디드 시스템에 널리 사용됩니다.

### APB 신호선

- **PCLK**: 클럭
- **PRESETn**: 리셋 (Active Low)
- **PADDR**: 주소 버스
- **PSEL**: 슬레이브 선택 신호
- **PENABLE**: Access 단계 활성화 신호
- **PWRITE**: 쓰기/읽기 제어 신호 (1: Write, 0: Read)
- **PWDATA**: 쓰기 데이터 버스
- **PRDATA**: 읽기 데이터 버스
- **PREADY**: 슬레이브 준비 완료 신호

---

## ⚙️ 설계 구조

본 프로젝트는 APB 버스를 통해 CPU(Master)와 여러 주변장치(Slaves)가 연결되는 구조를 가집니다.

- **APB Master**: CPU와 연결되어 APB 버스 트랜잭션을 제어
- **APB Slaves**:
  - **Timer**: 지정된 시간 간격으로 인터럽트 발생
  - **GPIO (General-Purpose Input/Output)**: 범용 입출력 포트 제어
  - **UART (Universal Asynchronous Receiver-Transmitter)**: 비동기 직렬 통신
- **APB Decoder**: 주소(`PADDR`)를 기반으로 여러 Slave 중 하나를 선택(`PSEL`)하는 역할
- **APB MUX**: 여러 Slave의 읽기 데이터(`PRDATA`) 중 선택된 Slave의 데이터를 Master로 전달

---

## 🔬 검증 (Verification)

클래스 기반의 SystemVerilog 테스트벤치를 구축하여 설계된 각 모듈과 전체 시스템의 기능을 검증했습니다.

- **검증 환경**: UVM(Universal Verification Methodology)과 유사한 클래스 기반 테스트벤치 구조 사용
- **검증 대상**: APB Master, Slaves (GPIO, UART), RAM
- **주요 검증 항목**:
  - APB 프로토콜에 맞는 쓰기/읽기 동작 검증
  - 각 주변장치의 고유 기능 (GPIO 입출력, UART 송수신) 검증
  - 주소 디코딩 및 데이터 멀티플렉싱 정확성 검증

---

## 🔧 문제 해결 (Troubleshooting)

프로젝트 진행 중 발생한 주요 문제와 해결 과정을 기록합니다.

- **문제 1**: APB 프로토콜 타이밍 위반
  - **원인**: `PENABLE` 신호가 한 클럭 늦게 비활성화되는 문제
  - **해결**: 상태 머신(FSM)의 상태 전이 로직을 수정하여 정확한 타이밍 준수
- **문제 2**: GPIO 모듈의 데이터 오기입
  - **원인**: 출력 포트(`output_port`)의 리셋 로직 부재
  - **해결**: 리셋 신호(`PRESETn`)가 활성화될 때 `output_port`가 0으로 초기화되도록 로직 추가

---

## 🤔 고찰

이번 프로젝트를 통해 AMBA APB 프로토콜의 동작 원리를 깊이 이해하고, 실제 RISC-V CPU와 연동되는 주변장치를 직접 설계 및 검증하는 경험을 쌓을 수 있었습니다. 특히 클래스 기반의 테스트벤치를 활용하여 체계적으로 버그를 찾아내고 수정하는 과정은 하드웨어 설계에서 검증의 중요성을 다시 한번 깨닫는 계기가 되었습니다. 향후 AHB나 AXI와 같은 고속 버스 프로토콜을 학습하고 더 복잡한 SoC(System-on-Chip)를 설계하는 기반을 마련했습니다.