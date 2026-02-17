pragma Singleton
import QtQuick

QtObject {
    id: root

    function doLayout(windowList, outerWidth, outerHeight) {
        var N = windowList.length
        if (N === 0) return []

        // Configurações
        var maxPerRow = 4
        var gap = 20  // Espaço entre janelas
        
        // Safe Area (90% da tela)
        var contentScale = 1
        var useW = outerWidth * contentScale
        var useH = outerHeight * contentScale

        // Calcula número de linhas necessárias
        var rows = Math.ceil(N / maxPerRow)
        var cols = Math.min(N, maxPerRow)
        
        // Calcula tamanho de cada thumbnail
        var thumbW = (useW - (cols - 1) * gap) / cols
        var thumbH = (useH - (rows - 1) * gap) / rows
        
        // Mantém aspect ratio 16:9 (padrão de janelas)
        var aspectRatio = 16 / 9
        
        // Ajusta para caber na tela mantendo proporção
        if (thumbW / thumbH > aspectRatio) {
            // Muito largo, limita pela altura
            thumbW = thumbH * aspectRatio
        } else {
            // Muito alto, limita pela largura
            thumbH = thumbW / aspectRatio
        }
        
        // Recalcula dimensões totais do grid
        var totalGridW = 0
        var totalGridH = thumbH * rows + gap * (rows - 1)
        var result = []
        var currentRow = 0
        var currentCol = 0
        result.length = N
        
        for (var i = 0; i < N; i++) {
            var item = windowList[i]
            
            // Calcula quantas colunas tem nesta linha
            var itemsInThisRow = Math.min(maxPerRow, N - currentRow * maxPerRow)
            var rowWidth = thumbW * itemsInThisRow + gap * (itemsInThisRow - 1)
            
            // Centraliza esta linha horizontalmente
            var rowOffsetX = (outerWidth - rowWidth) / 2
            
            // Posição X e Y
            var xPos = rowOffsetX + currentCol * (thumbW + gap)
            var yPos = currentRow * (thumbH + gap)
            
            result[i] = {
                win: item.win,
                x: xPos,
                y: yPos,
                width: thumbW,
                height: thumbH
            }
            
            // Próxima posição
            currentCol++
            if (currentCol >= maxPerRow) {
                currentCol = 0
                currentRow++
            }
        }
        
        // Centraliza verticalmente todo o grid
        var verticalOffset = (outerHeight - totalGridH) / 2
        
        for (var j = 0; j < N; j++) {
            result[j].y += verticalOffset
        }
        
        return result
    }
}
