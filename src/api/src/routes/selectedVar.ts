import { SelectedVar } from '#generated/prisma/index.js'
import prisma from '#prisma.js'
import { Request, Response, Router } from 'express'

const router = Router()

router.get('/selectedvar', async (_: Request, res: Response) => {
  const selected = await prisma.selectedVar.findMany()

  if (selected.length === 0) {
    res.status(404).json({ message: 'No selected variants found' })
    return
  }

  res.status(200).json(selected)
})

router.get('/selectedvar/:id', async (req: Request, res: Response) => {
  const selected = await prisma.selectedVar.findUnique({
    where: { id: req.params.id }
  })

  if (!selected) {
    res.status(404).json({ message: 'Selected variant not found' })
    return
  }

  res.status(200).json(selected)
})

router.post('/selectedvar', async (req: Request, res: Response) => {
  const { variant_id, answer_id } = req.body as SelectedVar

  if (!variant_id || !answer_id) {
    res.status(400).json({ message: 'Missing required fields' })
    return
  }

  const selected = await prisma.selectedVar.create({
    data: { variant_id, answer_id }
  })

  res.status(201).json(selected)
})

router.put('/selectedvar/:id', async (req: Request, res: Response) => {
  const { variant_id, answer_id } = req.body as SelectedVar

  const selected = await prisma.selectedVar.update({
    data: { variant_id, answer_id },
    where: { id: req.params.id }
  })

  res.status(200).json(selected)
})

router.delete('/selectedvar/:id', async (req: Request, res: Response) => {
  const selected = await prisma.selectedVar.findUnique({
    where: { id: req.params.id }
  })

  if (!selected) {
    res.status(404).json({ message: 'Selected variant not found' })
    return
  }

  const deleted = await prisma.selectedVar.delete({
    where: { id: req.params.id }
  })

  res.status(200).json(deleted)
})

export default router
