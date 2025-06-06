import bodyParser from 'body-parser'
import chalk from 'chalk'
import express from 'express'
import { Request, Response } from 'express'
import morgan from 'morgan'

import questionRouter from './routes/question.js'
import typeRouter from './routes/type.js'
import variantRouter from './routes/variant.js'
import selectedVarRouter from './routes/selectedVar.js'

const PORT = process.env.PORT ?? 3000
const app = express()

app.use(bodyParser.json())
app.use(morgan('combined'))

app.use(questionRouter)
app.use(typeRouter)
app.use(variantRouter)
app.use(selectedVarRouter)

app.get('/', (_: Request, res: Response) => {
  res.json({ message: 'Welcome to the Express + TypeScript Server!' })
})

app.listen(PORT, () => {
  console.log(
    chalk.bgGreenBright(
      `The server is running at http://localhost:${PORT.toString()}`
    )
  )
})
