# Blueprint do Aplicativo IoT LoRa

## Visão Geral

Este documento descreve a arquitetura, design e recursos do aplicativo IoT LoRa. O objetivo do aplicativo é provisionar, monitorar e interagir com múltiplos dispositivos LoRaWAN usando um smartphone, com suporte para múltiplos utilizadores em diferentes localizações geográficas.

## Arquitetura de Roteamento (Escalável)

O sistema foi atualizado para uma arquitetura de roteamento dinâmico que permite o suporte a múltiplos dispositivos finais através de um único gateway.

### Fluxo de Uplink (Dispositivo -> Nuvem)

1.  **Envio:** O dispositivo final (ESP32) envia uma mensagem LoRa em formato JSON, que inclui obrigatoriamente o seu endereço MAC no campo `"from_mac"`.
2.  **Roteamento no Gateway:** O gateway recebe o pacote LoRa, analisa o JSON e extrai o MAC address do remetente.
3.  **Caminho Dinâmico:** O gateway remove os dois pontos (`:`) do MAC address e usa-o para construir um caminho único no Firebase Realtime Database. Por exemplo: `/devices/AABBCC112233/uplink`.
4.  **Publicação:** A mensagem original é publicada nesse caminho dinâmico. Isto isola os dados de cada dispositivo, permitindo a escalabilidade.

### Fluxo de Downlink (Nuvem -> Dispositivo)

1.  **Publicação pela App:** A aplicação Flutter escreve a mensagem de downlink num caminho específico do dispositivo no Firebase, incluindo o MAC address do destinatário no campo `"to_mac"`. Ex: `/devices/AABBCC112233/downlink`.
2.  **Verificação pelo Gateway:** O gateway verifica periodicamente a base de dados `/devices`.
3.  **Descoberta:** Ele percorre cada dispositivo registado e verifica a existência de mensagens no sub-nó `downlink`.
4.  **Transmissão LoRa:** Se uma mensagem for encontrada, o gateway transmite-a via LoRa (em modo broadcast).
5.  **Filtragem no Destino:** Todos os dispositivos finais recebem a transmissão, mas apenas o dispositivo cujo MAC corresponde ao campo `"to_mac"` do JSON irá processar a mensagem.

## Design e Estilo

*   **UI Framework**: Flutter com Material Design 3
*   **Paleta de Cores**: Baseada em um `seedColor` de `Colors.deepPurple`.
*   **Tipografia**: `GoogleFonts` com Oswald para títulos e Roboto/Open Sans para o corpo do texto.
*   **Tema**: Suporte para os modos claro e escuro.

## Recursos

### Firmware (Gateway e Dispositivo)

*   **Roteamento Dinâmico no Gateway**: Suporta múltiplos dispositivos finais.
*   **Atualizações OTA**: Tanto o gateway como os dispositivos finais podem ser atualizados via Wi-Fi.
*   **Fila de Mensagens no Gateway**: Garante a entrega de mensagens mesmo com falhas de rede intermitentes.
*   **Provisionamento por QR Code**: Facilita o registo de novos dispositivos.
*   **Sistema de Convites para Grupos**: Os dispositivos têm a capacidade de receber, processar e responder a convites para se juntarem a grupos de comunicação.

### Aplicação Flutter

*   **Comunicação com Firebase**: Interage em tempo real com a base de dados.
*   **Visualização de Dispositivos**: Lista os dispositivos registados.
*   **Correção da Lógica de Chat**: A lógica de envio de mensagens foi corrigida para distinguir entre utilizadores e dispositivos. Mensagens para dispositivos são agora corretamente enviadas para o nó de `downlink` apropriado, garantindo a comunicação com o hardware.
*   **Confirmações de Leitura (Read Receipts)**:
    *   **Funcionalidade**: O sistema de chat agora suporta confirmações de leitura, similar ao WhatsApp, para indicar o estado das mensagens enviadas.
    *   **Estados Visuais**:
        *   Um "tick" cinzento: Mensagem enviada para o servidor (`sent`).
        *   Dois "ticks" cinzentos: Mensagem entregue ao destinatário (`delivered`).
        *   Dois "ticks" azuis: Mensagem lida pelo destinatário (`read`).
    *   **Privacidade do Utilizador**: Foi adicionado um ecrã de "Definições" onde o utilizador pode ativar ou desativar as confirmações de leitura. Se desativadas, o utilizador não enviará os seus "ticks" azuis nem verá os dos outros.
    *   **Abrangência**: Esta funcionalidade aplica-se tanto a conversas entre diferentes utilizadores da aplicação como a conversas entre um utilizador e um dispositivo ESP32.
*   **Partilha da Aplicação**:
    *   **Funcionalidade**: Foi adicionada uma opção no ecrã de "Definições" que permite ao utilizador partilhar a aplicação.
    *   **Método**: Utiliza a funcionalidade de partilha nativa do sistema operativo para enviar uma mensagem de texto com um link para a aplicação através de redes sociais, email, etc.
*   **Super-Dashboard do Administrador**:
    *   **Visão Geral**: A antiga e simples área de administração foi completamente substituída por um poderoso painel de gestão centralizado, projetado para fornecer uma visão completa da plataforma e ferramentas para a sua administração.
    *   **Componentes Principais**:
        *   **`AdminService`**: Um novo serviço que atua como o cérebro de dados para a área de administração. Ele simula a carga de um grande volume de dados (utilizadores, dispositivos, histórico de uplinks), preparando a arquitetura para escalar para um backend real.
        *   **Dashboard Principal (`/admin`)**: O novo ponto de entrada, que inclui:
            *   **Cartões de Métricas**: Indicadores visuais para "Total de Utilizadores", "Total de Dispositivos", "Dispositivos Ativos (24h)" e "Uplinks Hoje".
            *   **Gráfico de Atividade**: Um gráfico de barras (`fl_chart`) que mostra o volume de uplinks recebidos nas últimas 24 horas.
            *   **Menu de Navegação**: Botões que levam às várias sub-secções de gestão.
        *   **Secções de Gestão**:
            *   **Gestão de Utilizadores (`/admin/users`)**: Ecrã que lista todos os utilizadores registados e permite ao administrador ativar ou desativar as suas contas em tempo real.
            *   **Gestão de Dispositivos (`/admin/devices`)**: Ecrã que lista todos os dispositivos da plataforma, mostrando o seu estado (online/offline) e a quem pertencem.
            *   **Relatórios e Análise (`/admin/reports`)**: Uma secção para análise de dados, atualmente com um relatório de dispositivos inativos.
            *   **Mapa de Dispositivos (`/admin/map`)**: **(Em Desenvolvimento)** Um mapa interativo que exibe a localização geográfica de todos os dispositivos. Os marcadores indicarão o estado do dispositivo (online/offline) e permitirão o acesso rápido aos seus detalhes.
    *   **Acesso e Segurança**: O acesso ao dashboard continua protegido por uma palavra-passe ("admin"), solicitada a partir do botão de administração no ecrã inicial.
    *   **Tecnologias**: A funcionalidade foi construída utilizando `provider` para gestão de estado (via `AdminService`), `go_router` para a navegação hierárquica e `fl_chart` para a visualização de dados.
*   **Conversas em Grupo com Fluxo de Convite**:
    *   **Objetivo**: Permitir a criação de conversas com múltiplos utilizadores e dispositivos.
    *   **Modelo de Dados**:
        *   Um novo nó `/groups/{groupId}` será criado para armazenar os metadados de cada grupo, incluindo o nome e a lista de membros.
        *   Os membros dispositivos serão marcados com um estado (ex: `pending`) até que o convite seja aceite.
    *   **Fluxo de Criação e Convite**:
        1.  Um novo ecrã permitirá ao utilizador dar um nome ao grupo e selecionar membros (utilizadores e dispositivos).
        2.  O `GroupService` irá criar o grupo no Firebase.
        3.  Para cada **dispositivo** selecionado, uma mensagem de `downlink` contendo o convite (ex: `INVITE:{groupId}`) será enviada.
        4.  Para cada **utilizador** selecionado, o grupo aparecerá imediatamente na sua lista de conversas.
    *   **Aceitação pelo Dispositivo**:
        1.  O sistema (provavelmente o `GroupService`) irá monitorizar as mensagens de `uplink` dos dispositivos.
        2.  Ao receber uma resposta de aceitação (ex: `ACCEPT:{groupId}`), o estado do dispositivo no grupo será atualizado de `pending` para `accepted`.
    *   **Interface**: O ecrã de chat será adaptado para mostrar os nomes dos remetentes em grupos.
