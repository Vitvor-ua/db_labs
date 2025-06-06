-- CreateTable
CREATE TABLE "Variant" (
    "id" TEXT NOT NULL,
    "question_id" TEXT NOT NULL,
    "text" TEXT NOT NULL,

    CONSTRAINT "Variant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SelectedVar" (
    "id" TEXT NOT NULL,
    "variant_id" TEXT NOT NULL,
    "answer_id" TEXT NOT NULL,

    CONSTRAINT "SelectedVar_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Variant_id_key" ON "Variant"("id");

-- CreateIndex
CREATE UNIQUE INDEX "SelectedVar_id_key" ON "SelectedVar"("id");

-- AddForeignKey
ALTER TABLE "Variant" ADD CONSTRAINT "Variant_question_id_fkey" FOREIGN KEY ("question_id") REFERENCES "Question"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SelectedVar" ADD CONSTRAINT "SelectedVar_variant_id_fkey" FOREIGN KEY ("variant_id") REFERENCES "Variant"("id") ON DELETE CASCADE ON UPDATE CASCADE;
