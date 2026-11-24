# Prototipo físico de desactivación

Este módulo corresponde a una actividad dinamica universitaria independiente de la aplicación de escritorio. El firmware es un marcador para la fase 2; todavía no controla dispositivos ni se integra con la base de datos.

## Arquitectura prevista

- **ESP32:** controlador de estados, temporización y lectura de entradas.
- **LCD 16x2 con adaptador I2C:** muestra instrucciones, tiempo y estado.
- **Teclado matricial 4x4:** entrada de una secuencia o código del juego.
- **Cables de juego desmontables:** entradas digitales que simulan la selección de un cable; deben ser reutilizables, no conductores de alimentación que se corten físicamente.
- **Buzzer:** señales sonoras de interacción y fin de partida.
- **Boton de Timbre**: Pulsaciones breves o prolongadas.
- **Botones Switch Arcade**: pulsaciones cortas en secuencia.

El ESP32 leerá el teclado, botones y las entradas de juego, actualizará la pantalla y activará el buzzer según una máquina de estados (menu, espera, partida, éxito y fin de tiempo). La asignación de pines, el circuito y las reglas se definirán y comprobarán en la fase 2. La carpeta `firmware/` contiene únicamente el punto de partida.

## Seguridad y preparación

Use alimentación de baja tensión apropiada para los componentes y verifique las especificaciones de niveles lógicos: el ESP32 funciona a 3,3 V y algunos adaptadores LCD usan 5 V; emplee adaptación de nivel cuando sea necesaria. No corte cables energizados, no conecte cargas de red y supervise el montaje. Identifique el dispositivo claramente como juego y úselo solo en espacios autorizados.

Para desarrollar el firmware se necesitarán el entorno Arduino o PlatformIO, soporte para la placa ESP32 y bibliotecas compatibles con el LCD y el teclado. Aún no se han seleccionado versiones ni existe un procedimiento de compilación o cableado validado.
