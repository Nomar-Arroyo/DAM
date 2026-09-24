package com.example.myapplication2pantallas

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.myapplication2pantallas.ui.theme.MyApplication2PantallasTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MyApplication2PantallasTheme {
                App()
            }
        }
    }
}

@Composable
fun App() {
    var vendiendosegundaPantalla by remember { mutableStateOf(false) }

    if (vendiendosegundaPantalla) {
        SegundaPantalla(onVolver = { vendiendosegundaPantalla = false })
    } else {
        PrimeraPantalla(onContinuar = { vendiendosegundaPantalla = true })
    }
}

@Composable
fun PrimeraPantalla(onContinuar: () -> Unit) {
    Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "¡Hola! Soy la primera pantalla.",
                style = MaterialTheme.typography.headlineSmall,
                textAlign = TextAlign.Center
            )
            Text(
                text = "Presiona el botón para ver la respuesta en la segunda pantalla.",
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 12.dp)
            )
            Button(
                onClick = onContinuar,
                modifier = Modifier.padding(top = 24.dp)
            ) {
                Text("Ver respuesta")
            }
        }
    }
}

@Composable
fun SegundaPantalla(onVolver: () -> Unit) {
    Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Soy la segunda pantalla.",
                style = MaterialTheme.typography.headlineSmall,
                textAlign = TextAlign.Center
            )
            Text(
                text = "Esta es la respuesta: ¡la app funciona correctamente con dos pantallas!",
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 12.dp)
            )
            Button(
                onClick = onVolver,
                modifier = Modifier.padding(top = 24.dp)
            ) {
                Text("Volver")
            }
        }
    }
}

@Preview(showBackground = true, device = "spec:width=411dp,height=891dp,dpi=420", name = "Vista Celular")
@Composable
fun PhoneAppPreview() {
    MyApplication2PantallasTheme {
        App()
    }
}