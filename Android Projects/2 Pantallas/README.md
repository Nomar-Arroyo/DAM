# 2 Pantallas

App Android de dos pantallas hecha con **Jetpack Compose** y Material 3.

## Qué demuestra

Cómo se navega entre dos pantallas distintas en una app de Compose usando el
estado, sin necesidad de declarar activities ni fragments.

El estado es una sola variable booleana:

```kotlin
var vendiendosegundaPantalla by remember { mutableStateOf(false) }
```

El composable `App()` lee ese valor y decide cuál de las dos pantallas mostrar.
Al pulsar "Ver respuesta" pasa a `true`, y al pulsar "Volver" vuelve a `false`.

El detalle importante es que **cada pantalla declara su propio callback**
(`onContinuar` y `onVolver`) en lugar de tocar el estado directamente desde
dentro. Así la pantalla no sabe qué hay detrás: solo avisa de que el usuario
quiso continuar. Eso permite cambiar la navegación más adelante sin tocar las
pantallas.

## Estructura

```
app/src/main/java/com/example/myapplication2pantallas/
├── MainActivity.kt      Activities, navegación y las dos pantallas
└── ui/theme/            Colores, tipografía y tema de Material 3
```

## Cómo abrirlo

Abre la carpeta raíz del proyecto en Android Studio y pulsa **Run**, o bien:

```bash
cd "Android Projects/2 Pantallas"
./gradlew assembleDebug
```

## Requisitos

- Android Studio con el SDK de Android instalado
- JDK 17 o superior

## Nota

La app usa `enableEdgeToEdge()` y aplica el `innerPadding` que devuelve
`Scaffold`, de modo que el contenido no queda por debajo de la barra de estado
ni de la barra de navegación.